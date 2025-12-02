# Set tenant and app name
P2P_TENANT_NAME ?= $(TENANT_NAME)
P2P_APP_NAME ?= infra-tofu

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



.PHONY: lint-config
lint-config: ## Run config lint checks
	docker run --rm --mount type=bind,source=./p2p/config,target=/data docker.io/cytopia/yamllint -s .

.PHONY: lint-dockerfile
lint-dockerfile: ## Run dockerfile lint checks
	docker run --rm -i docker.io/hadolint/hadolint < Dockerfile

.PHONY: lint-app
lint-app: ## Run app lint checks
	docker run --rm --workdir=/srv/workspace --mount type=bind,source=.,target=/srv/workspace ghcr.io/opentofu/opentofu:latest fmt -check -diff -recursive
	docker run --rm --workdir=/srv/workspace --mount type=bind,source=.,target=/srv/workspace alpine/terragrunt:latest terragrunt hcl fmt --check

.PHONY: lint
lint: lint-config lint-dockerfile lint-app ## Run all lint checks



.PHONY: build-app
build-app: lint ## Build app
	docker buildx build $(p2p_image_cache) \
		--tag "$(p2p_image_tag)" \
		--build-arg P2P_VERSION="$(p2p_version)" \
		--file Dockerfile .

.PHONY: build-%
build-%:
	@echo "WARNING: $@ not implemented"



.PHONY: push-app
push-app:
	docker image push "$(p2p_image_tag)"

.PHONY: push-%
push-%:
	@echo "WARNING: $@ not implemented"



.PHONY: deploy-%
deploy-%:
	if [ -n "$(CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE)" ] ; then \
		mkdir -p ~/.config/gcloud ; \
		cat $(CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE) >> ~/.config/gcloud/application_default_credentials.json ; \
	fi
	docker run --rm -P --name "$(p2p_app_name)" \
		-v ~/.config/gcloud/:/root/.config/gcloud \
		-v "${PWD}/p2p/config/common.yaml:/app/common.yaml" \
		-v "${PWD}/p2p/config/$*.yaml:/app/config.yaml" \
		-e environment=$* \
		-e tenant_name=$(p2p_tenant_name) \
		-e app_name=$(p2p_app_name) \
		"$(p2p_registry)/$(p2p_app_name):$(p2p_version)" \
		make infra-apply



.PHONY: run-app
run-app: run-functional-app ## Run app

.PHONY: run-%-app
run-%-app:
	docker run --rm -P -it --name "$(p2p_app_name)-$*" \
		-v ~/.config/gcloud/:/root/.config/gcloud \
		-v "${PWD}/p2p/config/common.yaml:/app/common.yaml" \
		-v "${PWD}/p2p/config/$*.yaml:/app/config.yaml" \
		-e environment=$* \
		-e tenant_name=$(p2p_tenant_name) \
		-e app_name=$(p2p_app_name) \
		"$(p2p_image_tag)" \
		bash

.PHONY: run-%
run-%:
	@echo "WARNING: $@ not implemented"
