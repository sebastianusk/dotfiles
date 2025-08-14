# AWS Bedrock LiteLLM Proxy

This directory contains a setup for exposing AWS Bedrock models through an OpenAI-compatible API using LiteLLM proxy. This allows you to use AWS Bedrock models with any OpenAI-compatible client or application.

## Overview

The setup includes:
- **`model.sh`**: A bash script to manage the LiteLLM proxy server
- **`litellm_config.yaml`**: Configuration file defining available models and settings
- **`test/`**: Directory containing comprehensive test suite for validation

## Features

- 🚀 **OpenAI-compatible API** for AWS Bedrock models
- 🌏 **APAC Cross-Region Inference** profiles for better performance
- 🔧 **Easy server management** with start/stop/status commands
- 📊 **Process monitoring** and logging
- 🔄 **Automatic restart** functionality

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **AWS profile named "personal"** (or modify the script to use your profile)
3. **LiteLLM installed** (the script uses `uvx` to run it)
4. **Access to AWS Bedrock models** in the `ap-southeast-1` region

## Available Models

The proxy exposes these AWS Bedrock models (configured in `litellm_config.yaml`):

| Model Name | Model ID | Bedrock Model |
|------------|----------|---------------|
| claude-3-7-sonnet | `claude-3-7-sonnet` | `bedrock/apac.anthropic.claude-3-7-sonnet-20250219-v1:0` |
| claude-sonnet-4 | `claude-sonnet-4` | `bedrock/apac.anthropic.claude-sonnet-4-20250514-v1:0` |

Both models use APAC cross-region inference profiles for optimal performance and availability across Asia-Pacific regions.

## Usage

### Starting the Server

```bash
./model.sh start
```

This will:
- Start the LiteLLM proxy on `http://localhost:8000`
- Use AWS profile "personal"
- Set region to `ap-southeast-1`
- Log output to `/tmp/litellm_proxy.log`

### Stopping the Server

```bash
./model.sh stop
```

### Checking Status

```bash
./model.sh status
```

### Restarting the Server

```bash
./model.sh restart
```

## Configuration

### Environment Variables

You can customize the server configuration using environment variables:

```bash
# Change port (default: 8000)
PORT=9000 ./model.sh start

# Change host (default: 0.0.0.0)
HOST=127.0.0.1 ./model.sh start
```

### AWS Configuration

The script uses:
- **AWS Profile**: `personal`
- **AWS Region**: `ap-southeast-1`

To use a different profile, modify the `AWS_PROFILE` variable in the script.

### Model Configuration

Models are configured in `litellm_config.yaml`. The configuration file defines:

- **Model names**: Friendly names for API calls (e.g., `claude-3-haiku`)
- **Bedrock models**: Full AWS Bedrock model identifiers
- **AWS regions**: Region for each model (defaults to `ap-southeast-1`)
- **General settings**: API keys, logging, and other proxy settings

To add or modify models, edit the `model_list` section in `litellm_config.yaml`:

```yaml
model_list:
  - model_name: your-model-name
    litellm_params:
      model: bedrock/your.bedrock.model.id
      aws_region_name: ap-southeast-1
```

### Adding/Removing Models

To modify the available models, edit `litellm_config.yaml`:

```yaml
model_list:
  # Add new models here
  - model_name: claude-3-opus
    litellm_params:
      model: bedrock/anthropic.claude-3-opus-20240229-v1:0
      aws_region_name: ap-southeast-1
```

## API Usage

Once the server is running, you can use it with any OpenAI-compatible client:

### cURL Example

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-litellm-proxy" \
  -d '{
    "model": "claude-sonnet-4",
    "messages": [
      {
        "role": "user",
        "content": "Hello, how are you?"
      }
    ]
  }'
```

### Python Example

```python
import openai

client = openai.OpenAI(
    api_key="sk-litellm-proxy",
    base_url="http://localhost:8000/v1"
)

response = client.chat.completions.create(
    model="claude-sonnet-4",
    messages=[
        {"role": "user", "content": "Hello, how are you?"}
    ]
)

print(response.choices[0].message.content)
```

## Testing the Proxy

### Health Check

Test if the proxy is responding:

```bash
curl http://localhost:8000/health
```

### List Available Models

```bash
curl http://localhost:8000/v1/models \
  -H "Authorization: Bearer sk-litellm-proxy"
```

### Test Chat Completion

Test with Claude 3.7 Sonnet (balanced performance):

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-litellm-proxy" \
  -d '{
    "model": "claude-3-7-sonnet",
    "messages": [
      {
        "role": "user",
        "content": "Hello! Can you tell me a short joke?"
      }
    ],
    "max_tokens": 100
  }'
```

Test with Claude Sonnet 4 (most capable):

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-litellm-proxy" \
  -d '{
    "model": "claude-sonnet-4",
    "messages": [
      {
        "role": "user",
        "content": "Write a Python function to calculate factorial."
      }
    ],
    "max_tokens": 200
  }'
```

### Test Streaming Response

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-litellm-proxy" \
  -d '{
    "model": "claude-3-7-sonnet",
    "messages": [
      {
        "role": "user",
        "content": "Count from 1 to 5."
      }
    ],
    "stream": true,
    "max_tokens": 50
  }'
```

## Testing

This directory includes multiple testing options to validate the LiteLLM proxy functionality:

### 📁 **Test Files Overview**

All test files are located in the `test/` directory:

| File | Purpose | When to Use |
|------|---------|-------------|
| **`test/run-tests.sh`** | 🎯 **Main test runner** | **Start here** - provides menu of testing options |
| **`test/quick-test.sh`** | ⚡ **Fast validation** | Quick check that everything works (~30 seconds) |
| **`test/test.sh`** | 🔬 **Comprehensive suite** | Full automated testing of all features |
| **`test/TEST_CHECKLIST.md`** | 📋 **Manual checklist** | Step-by-step manual testing guide |

### 🎯 **Which Test Should I Use?**

#### **For Quick Validation (Recommended)**
```bash
cd test
./run-tests.sh quick
```
- **Use when**: You want to quickly verify the setup works
- **Tests**: Core functionality (start/stop/API/chat)
- **Time**: ~30 seconds
- **Perfect for**: After setup, before deployment, daily checks

#### **For Comprehensive Testing**
```bash
cd test
./run-tests.sh full
```
- **Use when**: You want to test everything thoroughly
- **Tests**: All features including edge cases
- **Time**: ~3-5 minutes
- **Perfect for**: After changes, before production, troubleshooting

#### **For Manual Testing**
```bash
cd test
./run-tests.sh manual
```
- **Use when**: You want to test step-by-step manually
- **Shows**: Detailed checklist with expected results
- **Perfect for**: Learning the system, debugging issues

#### **For Help**
```bash
cd test
./run-tests.sh help
```
- Shows all available testing options

### 🔍 **What Each Test File Does**

#### **`test/run-tests.sh` - Main Test Runner**
- **Purpose**: Provides a simple menu to choose testing type
- **Features**: 
  - Easy-to-use interface
  - Colored output
  - Help system
- **Options**: `quick`, `full`, `manual`, `help`

#### **`test/quick-test.sh` - Fast Validation**
- **Purpose**: Validates core functionality quickly
- **Tests**:
  1. ✅ Help command works
  2. ✅ Server starts successfully
  3. ✅ Status shows running
  4. ✅ API responds with models
  5. ✅ Chat completion works
  6. ✅ Server stops cleanly
- **Time**: ~30 seconds
- **Best for**: Regular validation

#### **`test/test.sh` - Comprehensive Suite**
- **Purpose**: Tests all functionality thoroughly
- **Tests**:
  - All quick tests +
  - Duplicate start prevention
  - Restart functionality
  - Custom port configuration
  - Environment variables
  - Error handling
  - Both Claude models
  - API edge cases
- **Time**: ~3-5 minutes
- **Best for**: Complete validation

#### **`test/TEST_CHECKLIST.md` - Manual Guide**
- **Purpose**: Step-by-step manual testing instructions
- **Contains**:
  - Exact commands to run
  - Expected outputs
  - Troubleshooting steps
  - Performance expectations
- **Best for**: Learning and debugging

### 🚀 **Quick Start Testing**

1. **First time setup validation**:
   ```bash
   cd test
   ./run-tests.sh quick
   ```

2. **If quick test fails, run manual checklist**:
   ```bash
   cd test
   ./run-tests.sh manual
   ```

3. **For complete validation**:
   ```bash
   cd test
   ./run-tests.sh full
   ```

### 🎯 **Test Results Interpretation**

#### **✅ All Tests Pass**
- Your setup is working perfectly
- Ready for production use
- Both Claude models are accessible

#### **❌ Some Tests Fail**
- Check AWS credentials: `aws sts get-caller-identity --profile personal`
- Verify model access in AWS Bedrock console
- Check logs: `tail -f /tmp/litellm_proxy.log`
- Follow troubleshooting section below

### 📊 **Expected Test Performance**

| Test Type | Duration | Tests Run | Purpose |
|-----------|----------|-----------|---------|
| Quick | ~30 seconds | 6 core tests | Daily validation |
| Full | ~3-5 minutes | 12+ comprehensive tests | Complete verification |
| Manual | Variable | 15+ step-by-step | Learning/debugging |

### Test Runner (Recommended)

Use the test runner for easy testing:
```bash
# Navigate to test directory
cd test

# Quick validation (recommended)
./run-tests.sh quick

# Comprehensive testing
./run-tests.sh full

# Show manual checklist
./run-tests.sh manual

# Show help
./run-tests.sh help
```

### Individual Test Scripts

Run specific test scripts directly:
```bash
# Navigate to test directory
cd test

# Quick validation tests
./quick-test.sh

# Comprehensive test suite
./test.sh
```

### Manual Testing

Follow the step-by-step checklist in `test/TEST_CHECKLIST.md` for manual verification of all functionality.

## Troubleshooting

### Server Won't Start

1. Check if the port is already in use:
   ```bash
   lsof -i :8000
   ```

2. Verify AWS credentials:
   ```bash
   aws sts get-caller-identity --profile personal
   ```

3. Check the logs:
   ```bash
   tail -f /tmp/litellm_proxy.log
   ```

### Model Access Issues

Ensure you have access to the Bedrock models in your AWS account:

```bash
aws bedrock list-foundation-models --region ap-southeast-1 --profile personal
```

### Connection Issues

If you're getting connection refused errors:

1. Verify the server is running: `./model.sh status`
2. Check firewall settings
3. Try connecting to `127.0.0.1` instead of `localhost`

## Logs

Server logs are written to `/tmp/litellm_proxy.log`. You can monitor them in real-time:

```bash
tail -f /tmp/litellm_proxy.log
```

## Security Notes

- The proxy runs on all interfaces (`0.0.0.0`) by default
- Consider restricting access in production environments
- The API key `sk-litellm-proxy` is a placeholder - LiteLLM doesn't enforce authentication by default
- Ensure your AWS credentials are properly secured

## Performance Tips

- Use APAC cross-region inference profiles for better latency in Asia-Pacific regions
- Claude 3.7 Sonnet provides excellent balance of speed and capability for most tasks
- Claude Sonnet 4 provides the best quality for complex reasoning and analysis tasks
- Monitor your AWS Bedrock usage and costs

## Contributing

To add new models or modify the configuration:

1. Update the model constants in `model.sh`
2. Add the new model to the `MODELS` array
3. Update this README with the new model information
4. Test the configuration before committing changes
