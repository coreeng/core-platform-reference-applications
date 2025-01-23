projectDir := $(realpath $(dir $(firstword $(MAKEFILE_LIST))))
os := $(shell uname)
app_name = blank
tenant_name = $(TENANT_NAME)
image_name = $(app_name)
VERSION ?= $(shell git rev-parse --short HEAD)
image_tag = $(VERSION)
helm_test_timeout_duration = 2m

## Default to local registry unless it is set
REGISTRY ?= local

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
p2p-build: ## Builds the service image and pushes it to the registry
	docker build --file Dockerfile --tag $(REGISTRY)/$(FAST_FEEDBACK_PATH)/$(image_name):$(image_tag) .
	docker image push $(REGISTRY)/$(FAST_FEEDBACK_PATH)/$(image_name):$(image_tag)

.PHONY: p2p-functional
p2p-functional: ## Runs only functional tests
	@echo '### $@ not implemented ###'

.PHONY: p2p-nft
p2p-nft: ## Runs only NFT tests
	@echo '### $@ not implemented ###'

.PHONY: p2p-integration
p2p-integration: ## Runs only integration tests
	@echo '### $@ not implemented ###'

.PHONY: p2p-extended-test
p2p-extended-test: ## Runs extended tests
	@echo '### $@ not implemented ###'
	
.PHONY: p2p-prod
p2p-prod: ## Deploy to production
	@echo '### $@ not implemented ###'

.PHONY: p2p-promote-generic
p2p-promote-generic:
	corectl p2p promote $(image_name):${image_tag} \
		--source-stage $(source_repo_path) \
		--dest-registry $(REGISTRY) \
		--dest-stage $(dest_repo_path)

.PHONY: p2p-promote-to-extended-test
p2p-promote-to-extended-test: source_repo_path=$(FAST_FEEDBACK_PATH)
p2p-promote-to-extended-test: dest_repo_path=$(EXTENDED_TEST_PATH)
p2p-promote-to-extended-test: p2p-promote-generic

.PHONY: p2p-promote-to-prod
p2p-promote-to-prod: source_repo_path=$(EXTENDED_TEST_PATH)
p2p-promote-to-prod: dest_repo_path=$(PROD_PATH)
p2p-promote-to-prod: p2p-promote-generic