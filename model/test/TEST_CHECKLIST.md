# LiteLLM Proxy Test Checklist

This checklist helps you manually verify all functionality of the LiteLLM proxy setup.

## Prerequisites
- [ ] AWS CLI configured with `personal` profile
- [ ] AWS SSO logged in: `aws sso login --profile personal`
- [ ] In the model directory: `cd /Users/admin/dotfiles/model`

## Basic Commands Test

### 1. Help Command
```bash
./model.sh
```
**Expected**: Shows usage help and exits with code 1

### 2. Status When Not Running
```bash
./model.sh status
```
**Expected**: "❌ LiteLLM proxy is not running"

### 3. Stop When Not Running
```bash
./model.sh stop
```
**Expected**: "❌ LiteLLM proxy is not running"

### 4. Start Server
```bash
./model.sh start
```
**Expected**: 
- "✅ LiteLLM proxy started successfully"
- Shows PID and server URL
- No error messages

### 5. Status When Running
```bash
./model.sh status
```
**Expected**: 
- "✅ LiteLLM proxy is running"
- Shows PID, server URL, and process info

### 6. Duplicate Start Prevention
```bash
./model.sh start
```
**Expected**: "❌ LiteLLM proxy is already running"

## API Tests

### 7. List Models
```bash
curl -H "Authorization: Bearer sk-litellm-proxy" http://localhost:8000/v1/models | python3 -m json.tool
```
**Expected**: JSON response with both models:
- `claude-3-7-sonnet`
- `claude-sonnet-4`

### 8. Chat Completion - Claude 3.7 Sonnet
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-litellm-proxy" \
  -d '{
    "model": "claude-3-7-sonnet",
    "messages": [{"role": "user", "content": "Hello! Say hi back."}],
    "max_tokens": 10
  }' | python3 -m json.tool
```
**Expected**: JSON response with `choices` array and assistant message

### 9. Chat Completion - Claude Sonnet 4
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-litellm-proxy" \
  -d '{
    "model": "claude-sonnet-4",
    "messages": [{"role": "user", "content": "Hello! Say hi back."}],
    "max_tokens": 10
  }' | python3 -m json.tool
```
**Expected**: JSON response with `choices` array and assistant message

### 10. Streaming Response
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-litellm-proxy" \
  -d '{
    "model": "claude-3-7-sonnet",
    "messages": [{"role": "user", "content": "Count from 1 to 3"}],
    "stream": true,
    "max_tokens": 20
  }'
```
**Expected**: Server-sent events with streaming response chunks

## Advanced Tests

### 11. Restart Server
```bash
./model.sh restart
```
**Expected**: 
- Shows stopping message with old PID
- Shows starting message with new PID
- Server works after restart

### 12. Custom Port
```bash
./model.sh stop
PORT=9000 ./model.sh start
```
**Expected**: Server starts on port 9000

Test API on custom port:
```bash
curl -H "Authorization: Bearer sk-litellm-proxy" http://localhost:9000/v1/models
```

### 13. Custom AWS Profile
```bash
./model.sh stop
AWS_PROFILE=default ./model.sh start
```
**Expected**: Startup message shows "Using AWS profile: default"

### 14. Stop Server
```bash
./model.sh stop
```
**Expected**: "✅ LiteLLM proxy stopped"

### 15. Final Status Check
```bash
./model.sh status
```
**Expected**: "❌ LiteLLM proxy is not running"

## Automated Tests

### Test Runner (from test directory)
```bash
cd test
./run-tests.sh quick    # Quick validation
./run-tests.sh full     # Comprehensive testing
./run-tests.sh manual   # Show this checklist
```

### Individual Test Scripts (from test directory)
```bash
cd test
./quick-test.sh         # Quick validation
./test.sh              # Comprehensive suite
```

## Troubleshooting

### Check Logs
```bash
tail -f /tmp/litellm_proxy.log
```

### Verify AWS Credentials
```bash
aws sts get-caller-identity --profile personal
```

### Check Process
```bash
ps aux | grep litellm
```

### Check Port Usage
```bash
lsof -i :8000
```

## Expected Performance

- **Startup time**: 2-5 seconds
- **API response time**: 1-3 seconds for Claude 3.7 Sonnet
- **API response time**: 3-8 seconds for Claude Sonnet 4
- **Memory usage**: ~50-100MB
- **CPU usage**: Low when idle

## Success Criteria

✅ **All tests pass** - The proxy is working correctly
✅ **Both models respond** - Claude 3.7 Sonnet and Sonnet 4 work
✅ **APAC inference profiles** - Using cross-region inference
✅ **Clean startup/shutdown** - No hanging processes
✅ **Environment variables** - Custom settings work
✅ **Error handling** - Graceful error messages
