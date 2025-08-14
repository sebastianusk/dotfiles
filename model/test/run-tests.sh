#!/bin/bash

# Test Runner for LiteLLM Proxy
# Provides options for different types of testing

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_usage() {
    echo -e "${BLUE}LiteLLM Proxy Test Runner${NC}"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  quick     - Run quick validation tests (recommended)"
    echo "  full      - Run comprehensive test suite"
    echo "  manual    - Show manual test checklist"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 quick    # Fast validation"
    echo "  $0 full     # Complete testing"
    echo "  $0 manual   # Manual checklist"
}

run_quick_tests() {
    echo -e "${GREEN}Running quick validation tests...${NC}\n"
    "$SCRIPT_DIR/quick-test.sh"
}

run_full_tests() {
    echo -e "${GREEN}Running comprehensive test suite...${NC}\n"
    echo -e "${YELLOW}Note: This may take several minutes${NC}\n"
    "$SCRIPT_DIR/test.sh"
}

show_manual_checklist() {
    echo -e "${GREEN}Manual Test Checklist${NC}\n"
    if [ -f "$SCRIPT_DIR/TEST_CHECKLIST.md" ]; then
        cat "$SCRIPT_DIR/TEST_CHECKLIST.md"
    else
        echo "TEST_CHECKLIST.md not found"
    fi
}

case "${1:-}" in
    quick)
        run_quick_tests
        ;;
    full)
        run_full_tests
        ;;
    manual)
        show_manual_checklist
        ;;
    help|--help|-h)
        show_usage
        ;;
    "")
        echo -e "${YELLOW}No option specified. Running quick tests by default.${NC}\n"
        run_quick_tests
        ;;
    *)
        echo -e "${YELLOW}Unknown option: $1${NC}\n"
        show_usage
        exit 1
        ;;
esac
