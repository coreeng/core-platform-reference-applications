projectDir := $(realpath $(dir $(firstword $(MAKEFILE_LIST))))
os := $(shell uname)
image_tag = $(VERSION)
image_name = blank-app
tenant_name = $(TENANT_NAME)

FAST_FEEDBACK_PATH = fast-feedback
EXTENDED_TEST_PATH = extended-test
PROD_PATH = prod

.PHONY: help-p2p
help-p2p:
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep p2p | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help-all
help-all:
	@grep -E '^[a-zA-Z1-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# P2P tasks

.PHONY: p2p-image
p2p-image:
	@echo $(image_name)

.PHONY: p2p-build
p2p-build: lint service-build service-push ## Builds the service image and pushes it to the registry

.PHONY: p2p-functional
p2p-functional: build-functional push-functional create-ns-functional deploy-functional ## Runs only functional tests

.PHONY: p2p-nft
p2p-nft: build-nft push-nft create-ns-nft deploy-nft ## Runs only NFT tests

.PHONY: p2p-extended-test
p2p-extended-test:  ## Runs extended tests
	@echo "### EXTENDED TESTS RUN ###"

.PHONY: p2p-prod
p2p-prod: deploy-prod ## Deploy app to production

## Namespace creation

.PHONY: create-ns-functional
create-ns-functional: ## Create namespace for functional tests
	@echo '### CREATE NS FUNCTIONAL ###'

.PHONY: create-ns-nft
create-ns-nft: ## Create namespace for NF tests
	@echo '### CREATE NS NFT ###'

## Internal Tasks, not part of the P2P

.PHONY: lint
lint: ## Linting the code
	@echo '### LINT ###'

.PHONY: service-build
service-build:
	@echo '### SERVICE BUILD FOR FAST-FEEDBACK ###'
	docker build --file Dockerfile --tag $(REGISTRY)/$(FAST_FEEDBACK_PATH)/$(image_name):$(image_tag) .

.PHONY: service-push
service-push: ## Push the service image
	docker image push $(REGISTRY)/$(FAST_FEEDBACK_PATH)/$(image_name):$(image_tag)
	@echo '### SERVICE PUSH FOR FAST-FEEDBACK ###'

.PHONY: build-functional
build-functional: ## Build the functional application, and package as a Docker image
	@echo '### BUILD FUNCTIONAL ###'

.PHONY: build-nft
build-nft: ## Build the non-functional-tests application, and package as a Docker image
	@echo '### BUILD NFT ###'

.PHONY: push-functional
push-functional: ## Push the Functional Docker image to an image registry
	@echo '### PUSH FUNCTIONAL ###'

.PHONY: push-nft
push-nft: ## Push the NFT Docker image to an image registry
	@echo '### PUSH NFT ###'

.PHONY: deploy-functional
deploy-functional: ## Deploy functional test application
	@echo '### DEPLOY FUNCTIONAL ###'

.PHONY: deploy-nft
deploy-nft:  ## Deploy nft application
	@echo '### DEPLOY NFT ###'

.PHONY: deploy-dev
deploy-dev:  ## Deploy application to dev environment
	@echo '### DEPLOY DEV ###'

.PHONY: deploy-prod
deploy-prod: ## Deploy application to production environment
	@echo $(image_tag)
	@echo $(REGISTRY)/release
	@echo '### DEPLOY PROD ###'

.PHONY: p2p-promote-generic
p2p-promote-generic:  ## Generic promote functionality
	@echo "$(red) Retagging version ${image_tag} from $(SOURCE_REGISTRY) to $(REGISTRY)"
	export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE=$(SOURCE_AUTH_OVERRIDE) ; \
	gcloud auth configure-docker --quiet europe-west2-docker.pkg.dev; \
	docker pull $(SOURCE_REGISTRY)/$(source_repo_path)/$(image_name):${image_tag} ; \
	docker tag $(SOURCE_REGISTRY)/$(source_repo_path)/$(image_name):${image_tag} $(REGISTRY)/$(dest_repo_path)/$(image_name):${image_tag}
	@echo "$(red) Pushing version ${image_tag}"
	export CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE=$(DEST_AUTH_OVERRIDE) ; \
	docker push $(REGISTRY)/$(dest_repo_path)/$(image_name):${image_tag}


.PHONY: p2p-promote-to-extended-test
p2p-promote-to-extended-test: source_repo_path=$(FAST_FEEDBACK_PATH)
p2p-promote-to-extended-test: dest_repo_path=$(EXTENDED_TEST_PATH)
p2p-promote-to-extended-test:  p2p-promote-generic

.PHONY: p2p-promote-to-prod
p2p-promote-to-prod:  source_repo_path=$(EXTENDED_TEST_PATH)
p2p-promote-to-prod:  dest_repo_path=$(PROD_PATH)
p2p-promote-to-prod:  p2p-promote-generic