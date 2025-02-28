# Set tenant and app name
P2P_TENANT_NAME ?= $(TENANT_NAME)
P2P_APP_NAME ?= blank

# Download and include p2p makefile
$(shell curl -fsSL "https://raw.githubusercontent.com/coreeng/p2p/v1/p2p.mk" -o ".p2p.mk")
include .p2p.mk

# Define required p2p targets
p2p-build:         build-app           push-app
p2p-functional:    build-functional    push-functional    deploy-functional    run-functional
p2p-nft:           build-nft           push-nft           deploy-nft           run-nft
p2p-integration:   build-integration   push-integration   deploy-integration   run-integration
p2p-extended-test: build-extended-test push-extended-test deploy-extended-test run-extended-test
p2p-prod:                                                 deploy-prod



.PHONY: lint
lint: ## Run lint checks
	docker run --rm -i docker.io/hadolint/hadolint < Dockerfile



.PHONY: build-app
build-app: lint ## Build app
	docker buildx build $(p2p_image_cache) --tag "$(p2p_image_tag)" --file Dockerfile .

.PHONY: build-%
build-%:
	@echo 'WARNING: $@ not implemented'



.PHONY: push-app
push-app:
	docker image push "$(p2p_image_tag)"

.PHONY: push-%
push-%:
	@echo 'WARNING: $@ not implemented'



.PHONY: deploy-%
deploy-%:
	@echo 'WARNING: $@ not implemented'



.PHONY: run-%
run-%:
	@echo 'WARNING: $@ not implemented'