#!/bin/bash
# Test suite runner for decoryou project

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
log_success() { echo -e "${GREEN}✅ $*${NC}"; }
log_error() { echo -e "${RED}❌ $*${NC}"; exit 1; }

log_info "Running test suite..."

# Count tests
total_tests=0
passed_tests=0
failed_tests=0

# Test 1: Terraform syntax
log_info "Test 1: Terraform syntax validation..."
if cd terraform && terraform fmt -check -recursive . >/dev/null 2>&1 && cd ..; then
    log_success "Terraform syntax OK"
    passed_tests=$((passed_tests + 1))
else
    log_error "Terraform syntax check failed"
    failed_tests=$((failed_tests + 1))
fi
total_tests=$((total_tests + 1))

# Test 2: Ansible syntax
log_info "Test 2: Ansible playbook syntax..."
if ansible-playbook --syntax-check ansible/site.yml >/dev/null 2>&1; then
    log_success "Ansible syntax OK"
    passed_tests=$((passed_tests + 1))
else
    log_error "Ansible syntax check failed"
    failed_tests=$((failed_tests + 1))
fi
total_tests=$((total_tests + 1))

# Test 3: Docker build
log_info "Test 3: Docker image build..."
if docker build -f docker/Dockerfile -t decoryou:test . >/dev/null 2>&1; then
    log_success "Docker build OK"
    passed_tests=$((passed_tests + 1))
else
    log_error "Docker build failed"
    failed_tests=$((failed_tests + 1))
fi
total_tests=$((total_tests + 1))

# Test 4: File linting
log_info "Test 4: YAML lint..."
if command -v yamllint &> /dev/null; then
    if yamllint -c "{extends: default}" ansible/ >/dev/null 2>&1; then
        log_success "YAML lint OK"
        passed_tests=$((passed_tests + 1))
    else
        log_error "YAML lint failed"
        failed_tests=$((failed_tests + 1))
    fi
else
    log_info "yamllint not installed, skipping"
fi
total_tests=$((total_tests + 1))

# Summary
log_info "================================"
log_info "Test Results: $passed_tests/$total_tests passed"
log_info "================================"

if [ $failed_tests -eq 0 ]; then
    log_success "All tests passed!"
    exit 0
else
    log_error "$failed_tests tests failed!"
    exit 1
fi
