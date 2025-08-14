#!/bin/bash

# Test Suite for LiteLLM Proxy Server
# This script tests all functionality of model.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_SCRIPT="$SCRIPT_DIR/../model.sh"

# Test helper functions
print_test_header() {
    echo -e "\n${BLUE}🧪 Test $((TOTAL_TESTS + 1)): $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ PASS${NC}"
    ((TESTS_PASSED++))
}

print_failure() {
    echo -e "${RED}❌ FAIL: $1${NC}"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

run_test() {
    ((TOTAL_TESTS++))
    local test_name="$1"
    local expected_exit_code="$2"
    shift 2
    local command="$@"
    
    print_test_header "$test_name"
    
    if output=$(eval "$command" 2>&1); then
        actual_exit_code=0
    else
        actual_exit_code=$?
    fi
    
    if [ "$actual_exit_code" -eq "$expected_exit_code" ]; then
        print_success
    else
        print_failure "Expected exit code: $expected_exit_code, Got: $actual_exit_code"
    fi
}

cleanup() {
    print_info "Cleaning up..."
    "$MODEL_SCRIPT" stop >/dev/null 2>&1 || true
    sleep 1
}

wait_for_server() {
    local port="${1:-8000}"
    local max_attempts=15
    local attempt=1
    
    print_info "Waiting for server on port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:$port/health" >/dev/null 2>&1 || \
           curl -s -H "Authorization: Bearer sk-litellm-proxy" "http://localhost:$port/v1/models" >/dev/null 2>&1; then
            print_info "Server is ready!"
            return 0
        fi
        sleep 2
        ((attempt++))
    done
    
    print_failure "Server failed to start within $((max_attempts * 2)) seconds"
    return 1
}

test_api() {
    ((TOTAL_TESTS++))
    local test_name="$1"
    local port="${2:-8000}"
    
    print_test_header "$test_name"
    
    if output=$(curl -s -H "Authorization: Bearer sk-litellm-proxy" "http://localhost:$port/v1/models" 2>&1); then
        if echo "$output" | grep -q '"claude-3-7-sonnet"' && echo "$output" | grep -q '"claude-sonnet-4"'; then
            print_success
        else
            print_failure "Models not found in response"
        fi
    else
        print_failure "API call failed"
    fi
}

test_chat() {
    ((TOTAL_TESTS++))
    local test_name="$1"
    local model="$2"
    local port="${3:-8000}"
    
    print_test_header "$test_name"
    
    local payload='{
        "model": "'$model'",
        "messages": [{"role": "user", "content": "Hi"}],
        "max_tokens": 5
    }'
    
    if output=$(curl -s -X POST "http://localhost:$port/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer sk-litellm-proxy" \
        -d "$payload" 2>&1); then
        
        if echo "$output" | grep -q '"choices"' && echo "$output" | grep -q '"content"'; then
            print_success
        else
            print_failure "Invalid chat response"
        fi
    else
        print_failure "Chat API call failed"
    fi
}

# Main test suite
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    LiteLLM Proxy Test Suite                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Ensure we start clean
    cleanup
    
    # Test 1: Help command
    run_test "Help command" 1 "$MODEL_SCRIPT"
    
    # Test 2: Status when not running
    run_test "Status when not running" 0 "$MODEL_SCRIPT status"
    
    # Test 3: Stop when not running
    run_test "Stop when not running" 1 "$MODEL_SCRIPT stop"
    
    # Test 4: Start server
    run_test "Start server" 0 "$MODEL_SCRIPT start"
    
    # Wait for server to be ready
    if wait_for_server; then
        
        # Test 5: Status when running
        run_test "Status when running" 0 "$MODEL_SCRIPT status"
        
        # Test 6: Duplicate start prevention
        run_test "Prevent duplicate start" 1 "$MODEL_SCRIPT start"
        
        # Test 7: API Models endpoint
        test_api "Models API endpoint"
        
        # Test 8: Chat with Claude 3.7 Sonnet
        test_chat "Chat - Claude 3.7 Sonnet" "claude-3-7-sonnet"
        
        # Test 9: Chat with Claude Sonnet 4
        test_chat "Chat - Claude Sonnet 4" "claude-sonnet-4"
        
        # Test 10: Restart
        run_test "Restart server" 0 "$MODEL_SCRIPT restart"
        
        # Wait after restart
        if wait_for_server; then
            # Test 11: API after restart
            test_api "API after restart"
        else
            print_failure "Server failed after restart"
            ((TESTS_FAILED++))
        fi
        
        # Test 12: Stop server
        run_test "Stop server" 0 "$MODEL_SCRIPT stop"
        
        # Test 13: Custom port
        print_test_header "Custom port test"
        if PORT=9000 "$MODEL_SCRIPT" start >/dev/null 2>&1; then
            if wait_for_server 9000; then
                test_api "Custom port API" 9000
                "$MODEL_SCRIPT" stop >/dev/null 2>&1
            else
                print_failure "Custom port server failed"
                ((TESTS_FAILED++))
            fi
        else
            print_failure "Failed to start on custom port"
            ((TESTS_FAILED++))
        fi
        
    else
        print_failure "Initial server start failed"
        ((TESTS_FAILED++))
    fi
    
    # Final cleanup
    cleanup
    
    # Test summary
    echo -e "\n${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                        Test Results                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "Total Tests: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All tests passed! The LiteLLM proxy is working perfectly.${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ $TESTS_FAILED test(s) failed. Please check the configuration.${NC}"
        exit 1
    fi
}

# Check if model.sh exists
if [ ! -f "$MODEL_SCRIPT" ]; then
    echo -e "${RED}❌ Error: model.sh not found at $MODEL_SCRIPT${NC}"
    exit 1
fi

# Make sure model.sh is executable
if [ ! -x "$MODEL_SCRIPT" ]; then
    echo -e "${YELLOW}⚠️  Making model.sh executable...${NC}"
    chmod +x "$MODEL_SCRIPT"
fi

# Run the test suite
main "$@"
