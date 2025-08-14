#!/bin/bash

# Quick Test for LiteLLM Proxy Server
# Tests core functionality quickly

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_SCRIPT="$SCRIPT_DIR/../model.sh"

echo -e "${BLUE}🚀 Quick Test Suite for LiteLLM Proxy${NC}\n"

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    "$MODEL_SCRIPT" stop >/dev/null 2>&1 || true
}

# Trap to ensure cleanup
trap cleanup EXIT

# Test 1: Help command
echo -e "${BLUE}Test 1: Help Command${NC}"
if "$MODEL_SCRIPT" >/dev/null 2>&1; then
    echo -e "${RED}❌ FAIL: Help should exit with code 1${NC}"
else
    echo -e "${GREEN}✅ PASS: Help command works${NC}"
fi

# Test 2: Start server
echo -e "\n${BLUE}Test 2: Start Server${NC}"
if "$MODEL_SCRIPT" start; then
    echo -e "${GREEN}✅ PASS: Server started${NC}"
else
    echo -e "${RED}❌ FAIL: Server failed to start${NC}"
    exit 1
fi

# Test 3: Status check
echo -e "\n${BLUE}Test 3: Status Check${NC}"
if "$MODEL_SCRIPT" status | grep -q "running"; then
    echo -e "${GREEN}✅ PASS: Status shows running${NC}"
else
    echo -e "${RED}❌ FAIL: Status check failed${NC}"
fi

# Test 4: Wait and test API
echo -e "\n${BLUE}Test 4: API Test${NC}"
echo "Waiting 10 seconds for server to be ready..."
sleep 10

if curl -s -H "Authorization: Bearer sk-litellm-proxy" "http://localhost:8000/v1/models" | grep -q "claude"; then
    echo -e "${GREEN}✅ PASS: API responds with models${NC}"
else
    echo -e "${RED}❌ FAIL: API test failed${NC}"
fi

# Test 5: Chat test
echo -e "\n${BLUE}Test 5: Chat Test${NC}"
CHAT_RESPONSE=$(curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-litellm-proxy" \
  -d '{
    "model": "claude-3-7-sonnet",
    "messages": [{"role": "user", "content": "Hi"}],
    "max_tokens": 5
  }')

if echo "$CHAT_RESPONSE" | grep -q "choices"; then
    echo -e "${GREEN}✅ PASS: Chat completion works${NC}"
else
    echo -e "${RED}❌ FAIL: Chat test failed${NC}"
    echo "Response: $CHAT_RESPONSE"
fi

# Test 6: Stop server
echo -e "\n${BLUE}Test 6: Stop Server${NC}"
if "$MODEL_SCRIPT" stop; then
    echo -e "${GREEN}✅ PASS: Server stopped${NC}"
else
    echo -e "${RED}❌ FAIL: Server stop failed${NC}"
fi

echo -e "\n${GREEN}🎉 Quick test completed!${NC}"
echo -e "${BLUE}For comprehensive testing, check the full test.sh script${NC}"
