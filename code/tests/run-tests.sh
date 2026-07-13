#!/usr/bin/env bash
# =============================================================================
# run-tests.sh — SmartHR Assistant Karate API Test Runner
#
# Usage:
#   ./run-tests.sh chapter-01
#   ./run-tests.sh chapter-02
#
# What it does (in order):
#   1. Validates the chapter argument
#   2. Builds every app required for the chapter  (mvn clean package)
#   3. Starts every app in the background, in order (mvn spring-boot:run)
#   4. Polls each app's port until it is ready
#   5. Runs the matching Karate feature file       (mvn test -Dtest=ChapterXXTest)
#   6. Stops every app (always — even on test failure or Ctrl-C)
#   7. Exits with the Karate exit code (0 = all passed, non-zero = failure)
#
# Most chapters are a single Spring Boot app on port 8080. Chapter 11 is a
# multi-module project with three apps — EXTRA_MODULES/EXTRA_PORTS below
# handle that case generically (build + start before the main app, stop after).
#
# Requirements:
#   - Java 25+, Maven 3.8+
#   - Ollama running locally with llama3.2 pulled (ollama pull llama3.2)
#   - Nothing else occupying the ports the chapter uses
# =============================================================================

set -euo pipefail

# ── Argument validation ───────────────────────────────────────────────────────

CHAPTER="${1:-}"

if [[ -z "$CHAPTER" ]]; then
    echo ""
    echo "  Usage : $0 <chapter>"
    echo ""
    echo "  Available chapters:"
    echo "    $0 chapter-01   ->  chapter-01-hr-chat.feature"
    echo "    $0 chapter-02   ->  chapter-02-core-concepts.feature"
    echo "    $0 chapter-03   ->  chapter-03-comparing-models.feature"
    echo "    $0 chapter-04   ->  chapter-04-prompt-engineering.feature"
    echo "    $0 chapter-05   ->  chapter-05-structured-output.feature"
    echo "    $0 chapter-06   ->  chapter-06-chat-memory.feature"
    echo "    $0 chapter-07   ->  chapter-07-rag.feature"
    echo "    $0 chapter-08   ->  chapter-08-pgvector.feature"
    echo "    $0 chapter-09   ->  chapter-09-neo4j.feature"
    echo "    $0 chapter-10   ->  chapter-10-function-calling.feature"
    echo "    $0 chapter-11   ->  chapter-11-mcp.feature (starts calendar-service, mcp-server, mcp-client)"
    echo "    $0 chapter-12   ->  chapter-12-multimodality.feature (requires: ollama pull llava)"
    echo "    $0 chapter-13   ->  chapter-13-streaming-api.feature"
    echo "    $0 chapter-14   ->  chapter-14-document-intelligence.feature"
    echo ""
    exit 1
fi

# ── Chapter -> module + test class mapping ────────────────────────────────────
#
# EXTRA_MODULES / EXTRA_PORTS are parallel arrays of additional apps that must
# be built and started (in array order) before APP_MODULE, and stopped (in
# reverse order) after the test run. Leave empty for single-app chapters.

EXTRA_MODULES=()
EXTRA_PORTS=()

case "$CHAPTER" in
    chapter-01)
        APP_MODULE="chapter-01-hello-spring-ai"
        TEST_CLASS="Chapter01Test"
        ;;
    chapter-02)
        APP_MODULE="chapter-02-core-concepts"
        TEST_CLASS="Chapter02Test"
        ;;
    chapter-03)
        APP_MODULE="chapter-03-comparing-models"
        TEST_CLASS="Chapter03Test"
        ;;
    chapter-04)
        APP_MODULE="chapter-04-prompt-engineering"
        TEST_CLASS="Chapter04Test"
        ;;
    chapter-05)
        APP_MODULE="chapter-05-structured-output"
        TEST_CLASS="Chapter05Test"
        ;;
    chapter-06)
        APP_MODULE="chapter-06-chat-memory"
        TEST_CLASS="Chapter06Test"
        ;;
    chapter-07)
        APP_MODULE="chapter-07-rag"
        TEST_CLASS="Chapter07Test"
        ;;
    chapter-08)
        APP_MODULE="chapter-08-pgvector"
        TEST_CLASS="Chapter08Test"
        ;;
    chapter-09)
        APP_MODULE="chapter-09-neo4j"
        TEST_CLASS="Chapter09Test"
        ;;
    chapter-10)
        APP_MODULE="chapter-10-function-calling"
        TEST_CLASS="Chapter10Test"
        ;;
    chapter-11)
        # Multi-module project: code/chapter-11-mcp-integration/{calendar-service,mcp-server,mcp-client}
        # Start order matters: calendar-service first, then mcp-server (calls it),
        # then mcp-client last (connects to mcp-server, the app under test on :8080).
        APP_MODULE="chapter-11-mcp-integration/mcp-client"
        TEST_CLASS="Chapter11Test"
        EXTRA_MODULES=("chapter-11-mcp-integration/calendar-service" "chapter-11-mcp-integration/mcp-server")
        EXTRA_PORTS=(8082 8081)
        ;;
    chapter-12)
        # Requires the llava vision model: ollama pull llava
        APP_MODULE="chapter-12-multimodality"
        TEST_CLASS="Chapter12Test"
        ;;
    chapter-13)
        APP_MODULE="chapter-13-streaming-api"
        TEST_CLASS="Chapter13Test"
        ;;
    chapter-14)
        APP_MODULE="chapter-14-document-intelligence"
        TEST_CLASS="Chapter14Test"
        ;;
    *)
        echo ""
        echo "  ERROR: Unknown chapter '$CHAPTER'"
        echo "  Available: chapter-01, chapter-02, chapter-03, chapter-04, chapter-05, chapter-06, chapter-07, chapter-08, chapter-09, chapter-10, chapter-11, chapter-12, chapter-13, chapter-14"
        echo ""
        exit 1
        ;;
esac

# ── Resolve absolute paths ────────────────────────────────────────────────────

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODE_DIR="$(cd "$TESTS_DIR/.." && pwd)"
APP_DIR="$CODE_DIR/$APP_MODULE"
APP_PORT=8080
APP_LOG="/tmp/smarthr-${CHAPTER}.log"

EXTRA_PIDS=()
EXTRA_LOGS=()

# ── Helpers ───────────────────────────────────────────────────────────────────

print_banner() {
    echo ""
    echo "============================================================"
    echo "  SmartHR Karate Tests"
    echo "  Chapter  : $CHAPTER"
    echo "  Module   : $APP_MODULE"
    echo "  Test     : $TEST_CLASS"
    echo "  App dir  : $APP_DIR"
    echo "  App log  : $APP_LOG"
    if [[ ${#EXTRA_MODULES[@]} -gt 0 ]]; then
        echo "  Extra apps: ${EXTRA_MODULES[*]} (ports: ${EXTRA_PORTS[*]})"
    fi
    echo "============================================================"
    echo ""
}

# Poll until HTTP port responds with any HTTP status code (1xx-5xx).
# A 404 is fine — it means the server is alive.
wait_for_port() {
    local port=$1
    local log=$2
    local max_seconds=90
    local interval=3
    local elapsed=0

    echo "  Polling http://localhost:${port}  (timeout: ${max_seconds}s)"

    while true; do
        local http_code
        http_code=$(curl -s -o /dev/null -w "%{http_code}" \
                    "http://localhost:${port}" 2>/dev/null || echo "000")

        if [[ "$http_code" =~ ^[1-5][0-9]{2}$ ]]; then
            echo "  App is ready (HTTP ${http_code}) after ${elapsed}s"
            return 0
        fi

        if [[ $elapsed -ge $max_seconds ]]; then
            echo ""
            echo "  ERROR: App did not respond within ${max_seconds}s."
            echo "         Check the log: $log"
            return 1
        fi

        printf "  Waiting... %ds\r" "$elapsed"
        sleep $interval
        elapsed=$((elapsed + interval))
    done
}

# Kill any process currently listening on the given TCP port.
# Handles Linux (lsof / fuser) and Windows / Git Bash (netstat + taskkill).
kill_port() {
    local port=$1
    local killed=0

    if command -v lsof > /dev/null 2>&1; then
        local pids
        pids=$(lsof -ti ":${port}" 2>/dev/null || true)
        if [[ -n "$pids" ]]; then
            echo "$pids" | xargs -r kill -9 2>/dev/null || true
            killed=1
        fi
    fi

    if [[ $killed -eq 0 ]] && command -v fuser > /dev/null 2>&1; then
        fuser -k "${port}/tcp" > /dev/null 2>&1 || true
        killed=1
    fi

    # Git Bash on Windows fallback
    if [[ $killed -eq 0 ]] && command -v netstat > /dev/null 2>&1 \
                            && command -v taskkill > /dev/null 2>&1; then
        local pids
        pids=$(netstat -ano 2>/dev/null \
               | grep ":${port}[[:space:]]" \
               | grep -i listening \
               | awk '{print $NF}' \
               | sort -u || true)
        for pid in $pids; do
            taskkill /F /PID "$pid" > /dev/null 2>&1 || true
        done
    fi
}

# ── Cleanup trap — always runs on exit (success, failure, or Ctrl-C) ──────────

MAVEN_PID=""

cleanup() {
    local exit_code=$?
    echo ""
    echo "------------------------------------------------------------"
    echo "  Stopping Spring Boot app(s)..."

    if [[ -n "$MAVEN_PID" ]]; then
        kill "$MAVEN_PID" 2>/dev/null || true
        sleep 2
    fi
    kill_port "$APP_PORT"

    # Stop extra apps in reverse start order
    for (( i=${#EXTRA_PIDS[@]}-1; i>=0; i-- )); do
        if [[ -n "${EXTRA_PIDS[$i]}" ]]; then
            kill "${EXTRA_PIDS[$i]}" 2>/dev/null || true
        fi
    done
    if [[ ${#EXTRA_PIDS[@]} -gt 0 ]]; then
        sleep 2
        for port in "${EXTRA_PORTS[@]}"; do
            kill_port "$port"
        done
    fi

    sleep 1
    echo "  App(s) stopped."
    echo "------------------------------------------------------------"
    echo ""
}

trap cleanup EXIT

# ── 1. Print banner ───────────────────────────────────────────────────────────

print_banner

# ── 2. Build every app ────────────────────────────────────────────────────────

STEP=1
for module in "${EXTRA_MODULES[@]}"; do
    echo "[${STEP}] Building $module ..."
    cd "$CODE_DIR/$module"
    mvn clean package -DskipTests --no-transfer-progress -q
    echo "    Build OK"
    STEP=$((STEP + 1))
done

echo "[${STEP}] Building $APP_MODULE ..."
cd "$APP_DIR"
mvn clean package -DskipTests --no-transfer-progress -q
echo "    Build OK"
echo ""

# ── 3. Start every app in order, waiting for each to be ready ────────────────

for i in "${!EXTRA_MODULES[@]}"; do
    module="${EXTRA_MODULES[$i]}"
    port="${EXTRA_PORTS[$i]}"
    log="/tmp/smarthr-${CHAPTER}-$(basename "$module").log"
    EXTRA_LOGS+=("$log")

    echo "Starting $module on port $port ..."
    echo "  Log file: $log"
    cd "$CODE_DIR/$module"
    mvn spring-boot:run --no-transfer-progress > "$log" 2>&1 &
    EXTRA_PIDS+=("$!")
    echo "  Maven PID: $!"

    if ! wait_for_port "$port" "$log"; then
        echo ""
        echo "  Aborting — $module failed to start. See log: $log"
        exit 1
    fi
    echo ""
done

echo "Starting $APP_MODULE on port $APP_PORT ..."
echo "  Log file: $APP_LOG"
cd "$APP_DIR"
mvn spring-boot:run --no-transfer-progress > "$APP_LOG" 2>&1 &
MAVEN_PID=$!
echo "  Maven PID: $MAVEN_PID"
echo ""

# ── 4. Wait until the main app is accepting connections ───────────────────────

echo "Waiting for $APP_MODULE to be ready ..."
if ! wait_for_port "$APP_PORT" "$APP_LOG"; then
    echo ""
    echo "  Aborting — app failed to start. See log: $APP_LOG"
    exit 1
fi
echo ""

# ── 5. Run Karate tests ───────────────────────────────────────────────────────

echo "Running Karate tests ($TEST_CLASS) ..."
echo ""

cd "$TESTS_DIR"

# Disable errexit so we capture the test exit code instead of aborting
set +e
mvn test -Dtest="$TEST_CLASS" --no-transfer-progress
TEST_EXIT=$?
set -e

# ── 6. Report ─────────────────────────────────────────────────────────────────

echo ""
echo "============================================================"
if [[ $TEST_EXIT -eq 0 ]]; then
    echo "  RESULT : ALL TESTS PASSED"
else
    echo "  RESULT : TESTS FAILED (exit code: $TEST_EXIT)"
fi
echo "  Chapter: $CHAPTER"
echo "  Report : $TESTS_DIR/target/karate-reports/karate-summary.html"
echo "============================================================"
echo ""

# cleanup trap fires here automatically
exit $TEST_EXIT
