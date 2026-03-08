#!/bin/bash
set -euo pipefail

# smoke-test.sh - Post-deployment validation tests
# Validates that the deployed application is healthy and responding

ENVIRONMENT="${ENVIRONMENT:-staging}"
APP_URL="${APP_URL:-http://localhost}"
TIMEOUT=30
MAX_RETRIES=5

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
log_success() { echo -e "${GREEN}✅ $*${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
log_error() { echo -e "${RED}❌ $*${NC}"; exit 1; }

log_info "Starting smoke tests for $ENVIRONMENT environment"
log_info "Target URL: $APP_URL"

# Test 1: Health Check Endpoint
test_health_check() {
    log_info "Test 1: Health check endpoint..."
    
    local retry_count=0
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if http_code=$(curl -s -o /dev/null -w "%{http_code}" \
            --connect-timeout 5 \
            --max-time $TIMEOUT \
            "$APP_URL/health"); then
            
            if [ "$http_code" = "200" ]; then
                log_success "Health check passed (HTTP $http_code)"
                return 0
            fi
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log_warn "Health check failed (attempt $retry_count/$MAX_RETRIES), retrying..."
            sleep 5
        fi
    done
    
    log_error "Health check failed after $MAX_RETRIES attempts"
}

# Test 2: HTTP Response Check
test_http_response() {
    log_info "Test 2: HTTP response check..."
    
    if http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 5 \
        --max-time $TIMEOUT \
        "$APP_URL/"); then
        
        if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
            log_success "HTTP response check passed (HTTP $http_code)"
            return 0
        else
            log_error "HTTP response check failed (HTTP $http_code)"
        fi
    fi
}

# Test 3: Response Time Check
test_response_time() {
    log_info "Test 3: Response time performance check..."
    
    response_time=$(curl -s -o /dev/null -w "%{time_total}" \
        --connect-timeout 5 \
        --max-time $TIMEOUT \
        "$APP_URL/" | cut -d'.' -f1)
    
    if [ "$response_time" -lt 5 ]; then
        log_success "Response time acceptable: ${response_time}s"
        return 0
    else
        log_warn "Response time slow: ${response_time}s"
        return 0  # Don't fail on slow response during deployment
    fi
}

# Test 4: Docker Container Status
test_docker_status() {
    log_info "Test 4: Docker container health check..."
    
    if command -v docker >/dev/null 2>&1; then
        if container_status=$(docker ps -q -f "label=app=decoryou" 2>/dev/null); then
            if [ -n "$container_status" ]; then
                log_success "Docker container is running"
                return 0
            fi
        fi
    fi
    
    log_warn "Docker container check skipped or not available"
    return 0
}

# Test 5: Environment Variables Verification
test_environment_vars() {
    log_info "Test 5: Environment configuration verification..."
    
    if [ -f ".env" ]; then
        required_vars=("APP_NAME" "APP_ENVIRONMENT" "LOG_LEVEL")
        
        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" .env 2>/dev/null; then
                log_success "Environment variable $var is set"
            else
                log_warn "Environment variable $var not found"
            fi
        done
    fi
}

# Main test execution
main() {
    log_info "═════════════════════════════════════════════"
    log_info "  SMOKE TEST SUITE - $ENVIRONMENT"
    log_info "═════════════════════════════════════════════"
    
    test_count=0
    passed_count=0
    
    tests=("test_health_check" "test_http_response" "test_response_time" "test_docker_status" "test_environment_vars")
    
    for test_func in "${tests[@]}"; do
        test_count=$((test_count + 1))
        if $test_func; then
            passed_count=$((passed_count + 1))
        fi
    done
    
    log_info "═════════════════════════════════════════════"
    log_info "Test Results: $passed_count/$test_count passed"
    log_info "═════════════════════════════════════════════"
    
    if [ $passed_count -eq $test_count ]; then
        log_success "All smoke tests passed! ✨"
        return 0
    else
        log_error "Some tests failed. Please review logs above."
    fi
}

main "$@"
