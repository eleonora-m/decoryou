#!/bin/bash
set -euo pipefail

# entrypoint.sh - Application entry point
# Handles setup and initialization before app startup

echo "🚀 Starting decoryou application..."

# Set defaults
: ${APP_ENV:=production}
: ${LOG_LEVEL:=info}
: ${PORT:=80}

# Export environment variables
export APP_ENV LOG_LEVEL PORT

# Wait for dependencies
echo "⏳ Waiting for dependencies..."

# Wait for database
if [ -n "${DATABASE_URL:-}" ]; then
    echo "🔎 Checking database connectivity..."
    max_attempts=30
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if nc -z "${DB_HOST:-localhost}" "${DB_PORT:-3306}" 2>/dev/null; then
            echo "✅ Database is ready"
            break
        fi
        attempt=$((attempt + 1))
        if [ $attempt -le $max_attempts ]; then
            sleep 1
        else
            echo "❌ Database not available after $max_attempts attempts"
            exit 1
        fi
    done
fi

# Wait for cache
if [ -n "${REDIS_URL:-}" ]; then
    echo "🔎 Checking Redis connectivity..."
    redis-cli -u "${REDIS_URL}" PING || true
fi

# Run migrations if provided
if [ -f "/app/migrations/migrate.sh" ]; then
    echo "🔄 Running migrations..."
    bash /app/migrations/migrate.sh
fi

# Start application
echo "🎯 Starting application on port $PORT..."
exec "$@"
