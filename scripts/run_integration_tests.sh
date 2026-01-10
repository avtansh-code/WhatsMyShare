#!/bin/bash

# Run Integration Tests with Firebase Emulators
# This script starts Firebase emulators and runs Flutter integration tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  WhatsMyShare Integration Test Runner  ${NC}"
echo -e "${YELLOW}========================================${NC}"

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_APP_DIR="$PROJECT_ROOT/flutter_app"
EMULATOR_DATA_DIR="$PROJECT_ROOT/emulator_data"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}Error: Firebase CLI is not installed${NC}"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter is not installed${NC}"
    exit 1
fi

# Function to check if emulators are already running
check_emulators_running() {
    if lsof -i:9099 > /dev/null 2>&1 || lsof -i:8080 > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Function to kill existing emulator processes
kill_existing_emulators() {
    echo -e "${YELLOW}Stopping any existing emulator processes...${NC}"
    
    # Kill Firebase emulator hub and related processes
    pkill -f "firebase.*emulators" 2>/dev/null || true
    pkill -f "java.*cloud-firestore-emulator" 2>/dev/null || true
    pkill -f "java.*cloud-storage-emulator" 2>/dev/null || true
    
    # Kill processes on emulator ports
    lsof -ti:9099 | xargs kill -9 2>/dev/null || true
    lsof -ti:8080 | xargs kill -9 2>/dev/null || true
    lsof -ti:9199 | xargs kill -9 2>/dev/null || true
    lsof -ti:4000 | xargs kill -9 2>/dev/null || true
    lsof -ti:4400 | xargs kill -9 2>/dev/null || true
    lsof -ti:4500 | xargs kill -9 2>/dev/null || true
    lsof -ti:5001 | xargs kill -9 2>/dev/null || true
    lsof -ti:9150 | xargs kill -9 2>/dev/null || true
    
    sleep 3
    echo -e "${GREEN}Existing emulator processes stopped${NC}"
}

# Function to initialize emulator data directory
init_emulator_data() {
    if [ ! -d "$EMULATOR_DATA_DIR" ]; then
        echo -e "${YELLOW}Creating emulator data directory...${NC}"
        mkdir -p "$EMULATOR_DATA_DIR"
        mkdir -p "$EMULATOR_DATA_DIR/auth_export"
        mkdir -p "$EMULATOR_DATA_DIR/firestore_export"
        mkdir -p "$EMULATOR_DATA_DIR/storage_export"
        
        # Create metadata file for Firebase emulator
        cat > "$EMULATOR_DATA_DIR/firebase-export-metadata.json" << 'EOF'
{
  "version": "13.0.0",
  "firestore": {
    "version": "1.19.0",
    "path": "firestore_export",
    "metadata_file": "firestore_export/firestore_export.overall_export_metadata"
  },
  "auth": {
    "version": "13.0.0",
    "path": "auth_export"
  },
  "storage": {
    "version": "13.0.0",
    "path": "storage_export"
  }
}
EOF
        
        # Create empty auth export
        echo '{"kind":"identitytoolkit#DownloadAccountResponse","users":[]}' > "$EMULATOR_DATA_DIR/auth_export/accounts.json"
        
        echo -e "${GREEN}Emulator data directory initialized${NC}"
    else
        echo -e "${GREEN}Emulator data directory already exists${NC}"
    fi
}

# Function to start emulators
start_emulators() {
    echo -e "${GREEN}Starting Firebase emulators...${NC}"
    cd "$PROJECT_ROOT"
    
    # Ensure any existing emulators are stopped first
    kill_existing_emulators
    
    # Initialize emulator data directory if needed
    init_emulator_data
    
    # Determine import flag based on whether data exists
    IMPORT_FLAG=""
    if [ -f "$EMULATOR_DATA_DIR/firebase-export-metadata.json" ]; then
        IMPORT_FLAG="--import=$EMULATOR_DATA_DIR"
    fi
    
    # Start emulators in background
    firebase emulators:start --only auth,firestore,storage $IMPORT_FLAG --export-on-exit="$EMULATOR_DATA_DIR" &
    EMULATOR_PID=$!
    
    # Wait for emulators to be ready
    echo -e "${YELLOW}Waiting for emulators to start...${NC}"
    
    # Wait up to 30 seconds for emulators to start
    MAX_WAIT=30
    WAIT_COUNT=0
    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        if check_emulators_running; then
            break
        fi
        sleep 1
        WAIT_COUNT=$((WAIT_COUNT + 1))
        echo -n "."
    done
    echo ""
    
    # Check if emulators started successfully
    if ! check_emulators_running; then
        echo -e "${RED}Failed to start emulators within ${MAX_WAIT} seconds${NC}"
        exit 1
    fi
    
    # Give extra time for all services to initialize
    sleep 3
    
    echo -e "${GREEN}Emulators are running!${NC}"
    echo "  - Auth Emulator: http://localhost:9099"
    echo "  - Firestore Emulator: http://localhost:8080"
    echo "  - Storage Emulator: http://localhost:9199"
    echo "  - Emulator UI: http://localhost:4000"
}

# Function to run integration tests
run_tests() {
    echo -e "${GREEN}Running integration tests...${NC}"
    cd "$FLUTTER_APP_DIR"
    
    # Temporarily rename dart_test.yaml to bypass skip configuration
    if [ -f "dart_test.yaml" ]; then
        mv dart_test.yaml dart_test.yaml.bak
    fi
    
    # Run integration tests directly
    flutter test test/integration/ --concurrency=1 --no-pub
    
    TEST_EXIT_CODE=$?
    
    # Restore dart_test.yaml
    if [ -f "dart_test.yaml.bak" ]; then
        mv dart_test.yaml.bak dart_test.yaml
    fi
    
    return $TEST_EXIT_CODE
}

# Function to cleanup
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    if [ ! -z "$EMULATOR_PID" ]; then
        kill $EMULATOR_PID 2>/dev/null || true
        # Wait for graceful shutdown
        sleep 2
    fi
    kill_existing_emulators
    echo -e "${GREEN}Cleanup complete${NC}"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Main execution
main() {
    echo ""
    
    # Parse arguments
    SKIP_EMULATOR_START=false
    FORCE_RESTART=false
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --skip-emulator-start) SKIP_EMULATOR_START=true ;;
            --force-restart) FORCE_RESTART=true ;;
            --help) 
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --skip-emulator-start  Skip starting emulators (use if already running)"
                echo "  --force-restart        Force restart emulators even if running"
                echo "  --help                 Show this help message"
                exit 0
                ;;
            *) echo "Unknown parameter: $1"; exit 1 ;;
        esac
        shift
    done
    
    # Check if emulators are already running
    if check_emulators_running; then
        echo -e "${YELLOW}Emulators appear to be already running${NC}"
        if [ "$FORCE_RESTART" = true ]; then
            echo -e "${YELLOW}Force restart requested...${NC}"
            kill_existing_emulators
            start_emulators
        elif [ "$SKIP_EMULATOR_START" = false ]; then
            echo -e "${YELLOW}Restarting emulators to ensure clean state...${NC}"
            kill_existing_emulators
            start_emulators
        fi
    else
        if [ "$SKIP_EMULATOR_START" = false ]; then
            start_emulators
        else
            echo -e "${RED}Error: Emulators not running and --skip-emulator-start was specified${NC}"
            exit 1
        fi
    fi
    
    # Run tests
    run_tests
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  All integration tests passed! ✓${NC}"
        echo -e "${GREEN}========================================${NC}"
    else
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}  Some integration tests failed ✗${NC}"
        echo -e "${RED}========================================${NC}"
    fi
    
    exit $EXIT_CODE
}

main "$@"