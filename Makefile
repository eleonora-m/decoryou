##########################################################################
# Makefile - Build and deployment automation for decoryou
##########################################################################

.PHONY: help init plan apply deploy destroy test lint fmt validate clean docker-build docker-compose-up docker-compose-down

# Default target
.DEFAULT_GOAL := help

# Variables
PROJECT_NAME := decoryou
ENVIRONMENT ?= dev
AWS_REGION ?= us-east-1
DOCKER_REGISTRY ?= decoryou
TERRAFORM_DIR := terraform
ANSIBLE_DIR := ansible

# Color output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

define log_info
	@echo -e "$(BLUE)ℹ️  $(1)$(NC)"
endef

define log_success
	@echo -e "$(GREEN)✅ $(1)$(NC)"
endef

define log_warn
	@echo -e "$(YELLOW)⚠️  $(1)$(NC)"
endef

define log_error
	@echo -e "$(RED)❌ $(1)$(NC)"
endef

##########################################################################
# HELP
##########################################################################

help:
	@echo "$(GREEN)decoryou - Production Infrastructure Manager$(NC)"
	@echo ""
	@echo "$(BLUE)Usage:$(NC)"
	@echo "  make $(BLUE)<target>$(NC) [$(YELLOW)ENVIRONMENT=<env>$(NC)]"
	@echo ""
	@echo "$(BLUE)Targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "  make init ENVIRONMENT=dev"
	@echo "  make plan ENVIRONMENT=staging"
	@echo "  make docker-build"
	@echo "  make validate"

##########################################################################
# SETUP & INITIALIZATION
##########################################################################

init: ## Initialize project dependencies
	$(call log_info,"Initializing project...")
	@command -v terraform >/dev/null 2>&1 || $(call log_error,"terraform not installed")
	@command -v ansible >/dev/null 2>&1 || $(call log_error,"ansible not installed")
	@command -v docker >/dev/null 2>&1 || $(call log_error,"docker not installed")
	$(call log_success,"All required tools are installed")

install-deps: ## Install development dependencies
	$(call log_info,"Installing dependencies...")
	pip install -r requirements.txt
	npm install
	$(call log_success,"Dependencies installed")

setup-env: ## Create .env file from example
	$(call log_info,"Setting up environment...")
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		$(call log_warn,"Created .env from .env.example"); \
		$(call log_warn,"Please update .env with your values"); \
	else \
		$(call log_info,".env already exists"); \
	fi

##########################################################################
# TERRAFORM TARGETS
##########################################################################

tf-init: ## Initialize Terraform
	$(call log_info,"Initializing Terraform for $(ENVIRONMENT)...")
	cd $(TERRAFORM_DIR) && \
		terraform init \
		-backend-config="bucket=$(PROJECT_NAME)-terraform-state-$(ENVIRONMENT)" \
		-backend-config="key=$(ENVIRONMENT)/terraform.tfstate" \
		-backend-config="region=$(AWS_REGION)"
	$(call log_success,"Terraform initialized")

tf-validate: ## Validate Terraform configuration
	$(call log_info,"Validating Terraform configuration...")
	cd $(TERRAFORM_DIR) && terraform validate
	$(call log_success,"Terraform validation passed")

tf-fmt: ## Format Terraform code
	$(call log_info,"Formatting Terraform code...")
	cd $(TERRAFORM_DIR) && terraform fmt -recursive .
	$(call log_success,"Terraform formatting complete")

tf-fmt-check: ## Check Terraform formatting
	$(call log_info,"Checking Terraform formatting...")
	cd $(TERRAFORM_DIR) && terraform fmt -check -recursive .

plan: tf-init ## Plan infrastructure changes (requires ENVIRONMENT=<env>)
	$(call log_info,"Planning Terraform changes for $(ENVIRONMENT)...")
	cd $(TERRAFORM_DIR) && \
		terraform plan \
		-var-file="environments/$(ENVIRONMENT)/terraform.tfvars" \
		-out=tfplan.$(ENVIRONMENT)
	$(call log_success,"Terraform plan complete")

apply: tf-init ## Apply infrastructure changes (requires ENVIRONMENT=<env>)
	@read -p "Are you sure you want to apply changes to $(ENVIRONMENT)? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(call log_info,"Applying Terraform changes..."); \
		cd $(TERRAFORM_DIR) && terraform apply tfplan.$(ENVIRONMENT); \
		$(call log_success,"Infrastructure updated"); \
	else \
		$(call log_warn,"Apply cancelled"); \
	fi

destroy: ## Destroy infrastructure (requires ENVIRONMENT=<env>)
	@read -p "WARNING: This will destroy all $(ENVIRONMENT) resources. Type '$(ENVIRONMENT)' to confirm: " confirm; \
	if [ "$$confirm" = "$(ENVIRONMENT)" ]; then \
		$(call log_error,"Destroying infrastructure..."); \
		cd $(TERRAFORM_DIR) && terraform destroy -var-file="environments/$(ENVIRONMENT)/terraform.tfvars"; \
		$(call log_success,"Infrastructure destroyed"); \
	else \
		$(call log_warn,"Destroy cancelled"); \
	fi

output: ## Display Terraform outputs
	$(call log_info,"Terraform outputs for $(ENVIRONMENT)...")
	cd $(TERRAFORM_DIR) && terraform output -json | jq .

##########################################################################
# ANSIBLE TARGETS
##########################################################################

ansible-lint: ## Lint Ansible playbooks
	$(call log_info,"Linting Ansible playbooks...")
	ansible-lint $(ANSIBLE_DIR)/site.yml
	$(call log_success,"Ansible linting passed")

ansible-syntax: ## Check Ansible syntax
	$(call log_info,"Checking Ansible syntax...")
	ansible-playbook --syntax-check $(ANSIBLE_DIR)/site.yml
	$(call log_success,"Ansible syntax valid")

ansible-deploy: ## Deploy with Ansible (requires ENVIRONMENT=<env>)
	$(call log_info,"Deploying with Ansible to $(ENVIRONMENT)...")
	ansible-playbook \
		-i $(ANSIBLE_DIR)/inventories/$(ENVIRONMENT)/hosts.yml \
		$(ANSIBLE_DIR)/site.yml
	$(call log_success,"Ansible deployment complete")

##########################################################################
# DOCKER TARGETS
##########################################################################

docker-build: ## Build Docker image
	$(call log_info,"Building Docker image...")
	docker build \
		-f docker/Dockerfile \
		-t $(DOCKER_REGISTRY):latest \
		-t $(DOCKER_REGISTRY):$$(git rev-parse --short HEAD) \
		.
	$(call log_success,"Docker image built")

docker-test: ## Test Docker image
	$(call log_info,"Testing Docker image...")
	docker run --rm $(DOCKER_REGISTRY):latest npm run test
	$(call log_success,"Docker tests passed")

docker-compose-up: setup-env ## Start Docker Compose stack
	$(call log_info,"Starting Docker Compose stack...")
	docker-compose up -d
	$(call log_success,"Docker Compose stack running")
	@echo ""
	@echo "$(GREEN)Access services:$(NC)"
	@echo "  App:        http://localhost:8080"
	@echo "  Grafana:    http://localhost:3000"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  MinIO:      http://localhost:9001"

docker-compose-down: ## Stop Docker Compose stack
	$(call log_info,"Stopping Docker Compose stack...")
	docker-compose down
	$(call log_success,"Docker Compose stack stopped")

docker-compose-logs: ## View Docker Compose logs
	docker-compose logs -f app

docker-compose-ps: ## Show Docker Compose running services
	docker-compose ps

##########################################################################
# VALIDATION & TESTING
##########################################################################

validate: tf-validate ansible-syntax ## Validate configurations
	$(call log_success,"All validations passed")

lint: tf-fmt-check ansible-lint ## Lint code
	$(call log_success,"Linting complete")

security-scan: ## Run security scans
	$(call log_info,"Running security scans...")
	@command -v tfsec >/dev/null 2>&1 && \
		(cd $(TERRAFORM_DIR) && tfsec . -f json) || \
		$(call log_warn,"tfsec not installed")
	@command -v checkov >/dev/null 2>&1 && \
		(checkov -d $(TERRAFORM_DIR) --output cli) || \
		$(call log_warn,"checkov not installed")

test: docker-test ## Run tests
	$(call log_success,"Tests passed")

##########################################################################
# UTILITY TARGETS
##########################################################################

fmt: tf-fmt ## Format all code
	$(call log_success,"Code formatted")

clean: ## Clean up temporary files
	$(call log_info,"Cleaning temporary files...")
	find . -name "*.tfplan*" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.pyc" -delete
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	$(call log_success,"Cleanup complete")

status: ## Show infrastructure status
	$(call log_info,"Infrastructure status:")
	docker-compose ps 2>/dev/null || echo "Docker Compose not running"
	@echo ""
	cd $(TERRAFORM_DIR) && terraform show -json | jq '.values.root_module | {resources_count: (.resources | length)}' 2>/dev/null || echo "Terraform state not available"

version: ## Display versions
	@echo "$(GREEN)Component Versions:$(NC)"
	@terraform version --json | jq '.terraform_version' || echo "Terraform not found"
	@ansible --version | head -1 || echo "Ansible not found"
	@docker --version || echo "Docker not found"

##########################################################################
# DOCUMENTATION
##########################################################################

docs: ## Open documentation in browser
	@which xdg-open >/dev/null 2>&1 && xdg-open docs/README.md || \
	which open >/dev/null 2>&1 && open docs/README.md || \
	echo "Please open docs/README.md manually"

##########################################################################
# DEPLOYMENT PIPELINE
##########################################################################

full-deploy: init validate lint plan apply ansible-deploy ## Full deployment pipeline (dev only)
	$(call log_success,"Full deployment complete!")

pipeline-dev: ENVIRONMENT=dev
pipeline-dev: full-deploy ## Run full pipeline for dev

pipeline-staging: ENVIRONMENT=staging
pipeline-staging: plan ## Plan staging deployment

pipeline-prod: ENVIRONMENT=prod
pipeline-prod: plan ## Plan production deployment (manual apply required)

##########################################################################
# .PHONY DECLARATIONS
##########################################################################

.PHONY: $(shell grep -E '^[a-zA-Z_-]+:' $(MAKEFILE_LIST) | sed 's/:.*//g')
