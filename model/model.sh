#!/bin/bash

# LiteLLM Proxy Server for AWS Bedrock Models
# This script exposes AWS Bedrock models via OpenAI-compatible API

set -e

# AWS Configuration
AWS_PROFILE=${AWS_PROFILE:-personal}
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-ap-southeast-1}
AWS_REGION=${AWS_REGION:-ap-southeast-1}

# Server Configuration
PORT=${PORT:-8000}
HOST=${HOST:-0.0.0.0}
PIDFILE="/tmp/litellm_proxy.pid"
LOGFILE="/tmp/litellm_proxy.log"
CONFIG_FILE="$(dirname "$0")/litellm_config.yaml"

# Function to show usage
show_usage() {
    echo "Usage: $0 {start|stop|status|restart}"
    echo ""
    echo "Commands:"
    echo "  start   - Start the LiteLLM proxy server"
    echo "  stop    - Stop the LiteLLM proxy server"
    echo "  status  - Show server status"
    echo "  restart - Restart the server (stop then start)"
    echo ""
    echo "Environment variables:"
    echo "  PORT              - Server port (default: 8000)"
    echo "  HOST              - Server host (default: 0.0.0.0)"
    echo "  AWS_PROFILE       - AWS profile to use (default: personal)"
    echo "  AWS_REGION        - AWS region (default: ap-southeast-1)"
    echo "  AWS_DEFAULT_REGION - AWS default region (default: ap-southeast-1)"
}

# Function to check if server is running
is_running() {
    if [ -f "$PIDFILE" ]; then
        local pid=$(cat "$PIDFILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            # PID file exists but process is dead, clean up
            rm -f "$PIDFILE"
            return 1
        fi
    else
        return 1
    fi
}

# Function to start the server
start_server() {
    if is_running; then
        echo "❌ LiteLLM proxy is already running (PID: $(cat $PIDFILE))"
        echo "📍 Server available at: http://${HOST}:${PORT}"
        return 1
    fi

    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Configuration file not found: $CONFIG_FILE"
        echo "Please ensure litellm_config.yaml exists in the same directory as this script."
        return 1
    fi

    echo "🚀 Starting LiteLLM proxy server..."
    echo "📍 Server will be available at: http://${HOST}:${PORT}"
    echo "🔧 Using AWS profile: ${AWS_PROFILE}"
    echo "🌏 Using AWS region: ${AWS_REGION}"
    echo "📋 Configuration file: $CONFIG_FILE"
    echo "📋 Logs will be written to: $LOGFILE"
    echo ""

    # Set AWS configuration for APAC cross-region inference
    export AWS_PROFILE="${AWS_PROFILE}"
    export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION}"
    export AWS_REGION="${AWS_REGION}"

    # Start LiteLLM proxy in background with configuration file
    nohup uvx --from 'litellm[proxy]' litellm --config "$CONFIG_FILE" \
        --port ${PORT} --host ${HOST} > "$LOGFILE" 2>&1 &

    local pid=$!
    echo $pid > "$PIDFILE"

    # Wait a moment and check if it started successfully
    sleep 2
    if is_running; then
        echo "✅ LiteLLM proxy started successfully (PID: $pid)"
        echo "📍 Server available at: http://${HOST}:${PORT}"
        echo "📋 Check logs: tail -f $LOGFILE"
    else
        echo "❌ Failed to start LiteLLM proxy"
        echo "📋 Check logs: cat $LOGFILE"
        return 1
    fi
}

# Function to stop the server
stop_server() {
    if ! is_running; then
        echo "❌ LiteLLM proxy is not running"
        return 1
    fi

    local pid=$(cat "$PIDFILE")
    echo "🛑 Stopping LiteLLM proxy (PID: $pid)..."

    kill "$pid"

    # Wait for process to stop
    local count=0
    while ps -p "$pid" > /dev/null 2>&1 && [ $count -lt 10 ]; do
        sleep 1
        count=$((count + 1))
    done

    if ps -p "$pid" > /dev/null 2>&1; then
        echo "⚠️  Process didn't stop gracefully, force killing..."
        kill -9 "$pid" 2>/dev/null || true
    fi

    rm -f "$PIDFILE"
    echo "✅ LiteLLM proxy stopped"
}

# Function to show status
show_status() {
    if is_running; then
        local pid=$(cat "$PIDFILE")
        echo "✅ LiteLLM proxy is running"
        echo "🆔 PID: $pid"
        echo "📍 Server: http://${HOST}:${PORT}"
        echo "📋 Logs: $LOGFILE"
        echo ""
        echo "📊 Process info:"
        ps -p "$pid" -o pid,ppid,cmd,etime,pcpu,pmem 2>/dev/null || echo "Unable to get process info"
    else
        echo "❌ LiteLLM proxy is not running"
    fi
}

# Function to restart the server
restart_server() {
    echo "🔄 Restarting LiteLLM proxy..."
    stop_server
    sleep 1
    start_server
}

# Main script logic
case "${1:-}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    status)
        show_status
        ;;
    restart)
        restart_server
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
