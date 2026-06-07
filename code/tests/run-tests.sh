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
#   2. Builds the chapter's Spring Boot app  (mvn clean package)
#   3. Starts the app in the background      (mvn spring-boot:run)
#   4. Polls port 8080 until the app is ready
#   5. Runs the matching Karate feature file  (mvn test -Dtest=ChapterXXTest)
#   6. Stops the app (always — even on test failure or Ctrl-C)
#   7. Exits with the Karate exit code (0 = all passed, non-zero = failure)
#
# Requirements:
#   - Java 21+, Maven 3.8+
#   - Ollama running locally with llama3.2 pulled (ollama pull llama3.2)
#   - Nothing else occupying port 8080
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
    echo ""
    exit 1
fi

# ── Chapter -> module + test class mapping ────────────────────────────────────

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
    *)
        echo ""
        echo "  ERROR: Unknown chapter '$CHAPTER'"
        echo "  Available: chapter-01, chapter-02, chapter-03, chapter-04"
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
    echo "============================================================"
    echo ""
}

# Poll until HTTP port responds with any HTTP status code (1xx-5xx).
# A 404 is fine — it means the server is alive.
wait_for_port() {
    local port=$1
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
            echo "         Check the log: $APP_LOG"
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
    echo "  Stopping Spring Boot app..."

    if [[ -n "$MAVEN_PID" ]]; then
        # Kill Maven and its entire child process tree
        kill "$MAVEN_PID" 2>/dev/null || true
        # Give the JVM a moment to shut down gracefully
        sleep 2
    fi

    # Kill any remaining process on the port (the forked JVM may outlive Maven)
    kill_port "$APP_PORT"
    sleep 1

    echo "  App stopped."
    echo "------------------------------------------------------------"
    echo ""
}

trap cleanup EXIT

# ── 1. Print banner ───────────────────────────────────────────────────────────

print_banner

# ── 2. Build the chapter app ──────────────────────────────────────────────────

echo "[1/4] Building $APP_MODULE ..."
cd "$APP_DIR"
mvn clean package -DskipTests --no-transfer-progress -q
echo "      Build OK"
echo ""

# ── 3. Start the app in the background ───────────────────────────────────────

echo "[2/4] Starting Spring Boot app on port $APP_PORT ..."
echo "      Log file: $APP_LOG"
mvn spring-boot:run --no-transfer-progress > "$APP_LOG" 2>&1 &
MAVEN_PID=$!
echo "      Maven PID: $MAVEN_PID"
echo ""

# ── 4. Wait until the app is accepting connections ────────────────────────────

echo "[3/4] Waiting for app to be ready ..."
if ! wait_for_port "$APP_PORT"; then
    echo ""
    echo "  Aborting — app failed to start. See log: $APP_LOG"
    exit 1
fi
echo ""

# ── 5. Run Karate tests ───────────────────────────────────────────────────────

echo "[4/4] Running Karate tests ($TEST_CLASS) ..."
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
