#!/bin/bash
set -euo pipefail

# deploy.sh - Orchestrates Terraform and Ansible deployment
# Usage: ./deploy.sh <environment> <version>

ENVIRONMENT="${1:-dev}"
VERSION="${2:-latest}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

log_info "Starting deployment for environment: $ENVIRONMENT, version: $VERSION"

# Validate environment
case "$ENVIRONMENT" in
    dev|staging|prod)
        log_info "Environment: $ENVIRONMENT"
        ;;
    *)
        log_error "Invalid environment. Use: dev, staging, prod"
        ;;
esac

# Check prerequisites
command -v terraform >/dev/null 2>&1 || log_error "terraform not found"
command -v ansible-playbook >/dev/null 2>&1 || log_error "ansible-playbook not found"
command -v aws >/dev/null 2>&1 || log_error "aws cli not found"

# Terraform Apply
log_info "Running Terraform for $ENVIRONMENT environment..."
cd "$(git rev-parse --show-toplevel)/terraform"

terraform init \
    -backend-config="bucket=decoryou-terraform-state-${ENVIRONMENT}" \
    -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
    -backend-config="dynamodb_table=decoryou-terraform-locks"

terraform validate
terraform plan \
    -var-file="environments/${ENVIRONMENT}/terraform.tfvars" \
    -out=tfplan.${ENVIRONMENT}

log_info "Review terraform plan and press enter to continue (or Ctrl+C to cancel)..."
read -r

terraform apply tfplan.${ENVIRONMENT}
log_success "Terraform apply completed"

# Get Outputs
DEPLOY_HOST=$(terraform output -raw app_host 2>/dev/null || echo "localhost")
log_info "Application deployed to: $DEPLOY_HOST"

# Ansible Deploy
log_info "Running Ansible playbook..."
cd "$(git rev-parse --show-toplevel)"

ansible-playbook \
    -i "ansible/inventories/${ENVIRONMENT}/hosts" \
    -e "docker_image=${ENVIRONMENT}-app:${VERSION}" \
    -e "app_environment=${ENVIRONMENT}" \
    -e "deployment_version=${VERSION}" \
    ansible/site.yml

log_success "Deployment completed successfully"

# Cleanup
rm -f "terraform/tfplan.${ENVIRONMENT}"

log_success "✨ Deployment pipeline finished"
