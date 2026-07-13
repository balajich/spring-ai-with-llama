#!/usr/bin/env bash
# Drives full Karate verification of every chapter under JDK 25 + GA deps.
# Apps run on port 8123 (8080 is held by the harness uvicorn); Karate points there.
set -u
export JAVA_HOME="C:/Program Files/Java/jdk-25.0.3"        # apps under test run on JDK 25
JDK21="C:/soft/jdk-21_windows-x64_bin/jdk-21.0.11"        # Karate 1.3.1 harness runs on JDK 21
PATH="$JAVA_HOME/bin:$PATH"
ROOT="C:/code/spring-ai-with-llama/code"
PORT=8123
RESULTS="/tmp/test_all_results.txt"
: > "$RESULTS"

log(){ echo "[$(date +%H:%M:%S)] $*"; }
kill_java(){ powershell -Command "Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force" >/dev/null 2>&1; sleep 3; }

ensure_ollama(){ curl -s -o /dev/null http://localhost:11434/api/tags --max-time 3 || { nohup ollama serve >/tmp/ollama.log 2>&1 & sleep 5; }; }

wait_ready(){ # logfile, timeout_s
  local lf=$1 to=$2 i
  for ((i=0;i<to;i+=3)); do
    grep -q "Started .*Application" "$lf" 2>/dev/null && return 0
    grep -qE "APPLICATION FAILED|BUILD FAILURE|Web server failed" "$lf" 2>/dev/null && return 1
    sleep 3
  done
  return 1
}

start_app(){ # dir, logfile, extra_arg
  local dir=$1 lf=$2 arg=${3:-}
  ( cd "$ROOT/$dir" && nohup mvn -q spring-boot:run -Dspring-boot.run.arguments="--server.port=$PORT $arg" >"$lf" 2>&1 & )
}

run_karate(){ # testclass -> echoes result line
  local tc=$1 out rc summary
  out=$(cd "$ROOT/tests" && mvn test -Dtest="$tc" -Dbase.url="http://localhost:$PORT" 2>&1)
  rc=$?
  echo "$out" > "/tmp/karate_${tc}.log"
  summary=$(echo "$out" | grep -oiE "scenarios: *[0-9]+ \| *passed: *[0-9]+ \| *failed: *[0-9]+" | tail -1)
  [ -z "$summary" ] && summary="(no summary; see /tmp/karate_${tc}.log)"
  if [ $rc -eq 0 ]; then echo "PASS  $summary"; return 0; else echo "FAIL  $summary"; return 1; fi
}

test_simple(){ # chapter_label, dir, testclass, timeout
  local label=$1 dir=$2 tc=$3 to=${4:-180}
  local lf="/tmp/app_${label}.log"
  log "=== $label : starting app ($dir) ==="
  kill_java
  start_app "$dir" "$lf"
  if wait_ready "$lf" "$to"; then
    log "$label app ready, running $tc"
    local res; res=$(run_karate "$tc")
    echo "$label  |  $res" | tee -a "$RESULTS"
  else
    echo "$label  |  APP FAILED TO START (see $lf)" | tee -a "$RESULTS"
    tail -5 "$lf" 2>/dev/null
  fi
  kill_java
}

ensure_ollama

# ---- single-app chapters ----
test_simple "ch01" "chapter-01-hello-spring-ai"   "Chapter01Test" 150
test_simple "ch02" "chapter-02-core-concepts"     "Chapter02Test" 150
test_simple "ch03" "chapter-03-comparing-models"  "Chapter03Test" 150
test_simple "ch04" "chapter-04-prompt-engineering" "Chapter04Test" 150
test_simple "ch05" "chapter-05-structured-output" "Chapter05Test" 150
test_simple "ch06" "chapter-06-chat-memory"       "Chapter06Test" 150
test_simple "ch07" "chapter-07-rag"               "Chapter07Test" 300
test_simple "ch10" "chapter-10-function-calling"  "Chapter10Test" 150
test_simple "ch12" "chapter-12-multimodality"     "Chapter12Test" 180
test_simple "ch13" "chapter-13-streaming-api"     "Chapter13Test" 150

# ---- ch08 pgvector (Docker) ----
log "=== ch08 : docker compose up (pgvector) ==="
docker compose -f "$ROOT/chapter-08-pgvector/docker-compose.yml" up -d >/tmp/ch08_docker.log 2>&1
for i in $(seq 1 30); do (echo > /dev/tcp/localhost/5432) >/dev/null 2>&1 && break; sleep 2; done
sleep 5
test_simple "ch08" "chapter-08-pgvector" "Chapter08Test" 300
docker compose -f "$ROOT/chapter-08-pgvector/docker-compose.yml" down >/dev/null 2>&1

# ---- ch09 neo4j (Docker) ----
log "=== ch09 : docker compose up (neo4j) ==="
docker compose -f "$ROOT/chapter-09-neo4j/docker-compose.yml" up -d >/tmp/ch09_docker.log 2>&1
for i in $(seq 1 40); do (echo > /dev/tcp/localhost/7687) >/dev/null 2>&1 && break; sleep 2; done
sleep 10
test_simple "ch09" "chapter-09-neo4j" "Chapter09Test" 300
docker compose -f "$ROOT/chapter-09-neo4j/docker-compose.yml" down >/dev/null 2>&1

# ---- ch11 MCP (3 processes) ----
log "=== ch11 : starting calendar-service(8082), mcp-server(8081), mcp-client($PORT) ==="
kill_java
( cd "$ROOT/chapter-11-mcp-integration/calendar-service" && nohup mvn -q spring-boot:run >/tmp/app_ch11_cal.log 2>&1 & )
wait_ready /tmp/app_ch11_cal.log 150 && log "calendar ready" || log "calendar FAILED"
( cd "$ROOT/chapter-11-mcp-integration/mcp-server" && nohup mvn -q spring-boot:run >/tmp/app_ch11_srv.log 2>&1 & )
wait_ready /tmp/app_ch11_srv.log 150 && log "mcp-server ready" || log "mcp-server FAILED"
( cd "$ROOT/chapter-11-mcp-integration/mcp-client" && nohup mvn -q spring-boot:run -Dspring-boot.run.arguments="--server.port=$PORT" >/tmp/app_ch11_cli.log 2>&1 & )
if wait_ready /tmp/app_ch11_cli.log 180; then
  log "mcp-client ready, running Chapter11Test"
  res=$(run_karate "Chapter11Test")
  echo "ch11  |  $res" | tee -a "$RESULTS"
else
  echo "ch11  |  CLIENT FAILED TO START" | tee -a "$RESULTS"
  tail -5 /tmp/app_ch11_cli.log
fi
kill_java

log "================= SUMMARY ================="
cat "$RESULTS"
log "DONE"
