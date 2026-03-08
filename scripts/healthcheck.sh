#!/bin/bash
set -euo pipefail

# healthcheck.sh - Application health check script
# Returns exit code 0 if healthy, non-zero otherwise

HEALTH_CHECK_URL="${HEALTH_CHECK_URL:-http://localhost:80/health}"
TIMEOUT="${TIMEOUT:-5}"
RETRIES="${RETRIES:-3}"

echo "🏥 Running health check..."
echo "   URL: $HEALTH_CHECK_URL"
echo "   Timeout: ${TIMEOUT}s"
echo "   Retries: $RETRIES"

attempt=1
while [ $attempt -le $RETRIES ]; do
    echo "   Attempt $attempt/$RETRIES..."
    
    if curl -sf \
        --connect-timeout "$TIMEOUT" \
        --max-time "$TIMEOUT" \
        "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
        echo "✅ Health check passed"
        exit 0
    fi
    
    if [ $attempt -lt $RETRIES ]; then
        sleep 2
    fi
    attempt=$((attempt + 1))
done

echo "❌ Health check failed after $RETRIES attempts"
exit 1
