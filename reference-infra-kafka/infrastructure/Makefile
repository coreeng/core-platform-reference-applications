# IaC path
IAC_PATH=code

SERVICE_PROJECT_ID := \
	$$(yq '.infrastructure_project_id' -o t config.yaml)



.PHONY: help
help:
	@echo "Usage:"
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' -h $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-30s %s\n", $$1, $$2}'



.PHONY: infra-init-cache
infra-init-cache:
	tofu -chdir="$(IAC_PATH)" init -lock=false -backend=false
	rm -rf "$(IAC_PATH)/.terraform"

.PHONY: infra-init-upgrade
infra-init-upgrade:
	tofu -chdir="$(IAC_PATH)" init -lock=false -backend=false -upgrade
	tofu -chdir="$(IAC_PATH)" providers lock --platform=darwin_amd64 --platform=darwin_arm64 --platform=linux_amd64 --platform=linux_arm64 --platform=windows_amd64
	rm -rf "$(IAC_PATH)/.terraform"

.PHONY: infra-init
infra-init: ## Terragrunt init
	terragrunt init --working-dir="$(IAC_PATH)" --non-interactive --backend-bootstrap -lock=false

.PHONY: infra-plan
infra-plan: ## Terragrunt plan
	@export USER_PROJECT_OVERRIDE=true ; \
	export GOOGLE_BILLING_PROJECT=$(SERVICE_PROJECT_ID) ; \
	terragrunt plan --working-dir="$(IAC_PATH)" --non-interactive --backend-bootstrap -lock=false -out="plan.zip"

.PHONY: infra-refresh
infra-refresh: ## Terragrunt refresh
	@export USER_PROJECT_OVERRIDE=true ; \
	export GOOGLE_BILLING_PROJECT=$(SERVICE_PROJECT_ID) ; \
	terragrunt refresh --working-dir="$(IAC_PATH)" --non-interactive --backend-bootstrap

.PHONY: infra-apply
infra-apply: ## Terragrunt apply
	@export USER_PROJECT_OVERRIDE=true ; \
	export GOOGLE_BILLING_PROJECT=$(SERVICE_PROJECT_ID) ; \
	terragrunt apply --working-dir="$(IAC_PATH)" --non-interactive --backend-bootstrap -auto-approve

.PHONY: infra-destroy
infra-destroy: ## Terragrunt destroy
	@export USER_PROJECT_OVERRIDE=true ; \
	export GOOGLE_BILLING_PROJECT=$(SERVICE_PROJECT_ID) ; \
	terragrunt destroy --working-dir="$(IAC_PATH)" --non-interactive -auto-approve

.PHONY: infra-output
infra-output: ## Terragrunt output
	terragrunt output --working-dir="$(IAC_PATH)"
