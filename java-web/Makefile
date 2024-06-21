projectDir := $(realpath $(dir $(firstword $(MAKEFILE_LIST))))
os := $(shell uname)
app_name = java-web
image_tag = $(VERSION)
image_name = $(app_name)
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
p2p-functional: build-functional push-functional create-ns-functional deploy-functional ## Runs only functional helm tests
	helm test $(app_name) -n $(app_name)-functional --filter name=reference-app-functional-test
	kubectl logs reference-app-functional-test -n $(app_name)-functional

.PHONY: p2p-nft
p2p-nft: build-nft push-nft create-ns-nft deploy-nft ## Runs only NFT helm tests

.PHONY: p2p-extended-test
p2p-extended-test:  ## Runs extended tests
	echo "### EXTENDED TESTS RUN ###"

.PHONY: p2p-prod
p2p-prod: create-ns-prod deploy-prod ## Deploy helm chart of the reference app to production namespace

## Namespace creation

.PHONY: create-ns-functional
create-ns-functional: ## Create namespace for functional tests
	awk -v NAME="$(tenant_name)" -v ENV="$(app_name)-functional" '{ \
		sub(/{parent}/, NAME);  \
		sub(/{child}/, ENV);  \
		print;  \
	}' resources/subns-anchor.yaml | kubectl apply -f -

.PHONY: create-ns-nft
create-ns-nft: ## Create namespace for NF tests
	awk -v NAME="$(tenant_name)" -v ENV="$(app_name)-nft" '{ \
		sub(/{parent}/, NAME);  \
		sub(/{child}/, ENV);  \
		print;  \
	}' resources/subns-anchor.yaml | kubectl apply -f -

.PHONY: create-ns-prod
create-ns-prod: ## Create namespace for production
	awk -v NAME="$(tenant_name)" -v ENV="$(app_name)" '{ \
		sub(/{parent}/, NAME);  \
		sub(/{child}/, ENV);  \
		print;  \
	}' resources/subns-anchor.yaml | kubectl apply -f -


## Internal Tasks, not part of the P2P

.PHONY: lint
lint: ## Linting go code
	echo '### LINT ###'

.PHONY: service-build
service-build:
	docker build --file Dockerfile --tag $(REGISTRY)/$(FAST_FEEDBACK_PATH)/$(image_name):$(image_tag) .

.PHONY: service-push
service-push: ## Push the service image
	docker image push $(REGISTRY)/$(FAST_FEEDBACK_PATH)/$(image_name):$(image_tag)

p2p-build: lint
	docker build --file Dockerfile --tag $(REGISTRY)/$(image_name):$(image_tag) .

.PHONY: build-functional
build-functional: ## Build the functional reference application, and package as a Docker image
	docker build --file functional/Dockerfile --tag $(REGISTRY)/$(FAST_FEEDBACK_PATH)/$(image_name)-functional:$(image_tag) .

.PHONY: build-nft
build-nft: ## Build the non-functional-tests reference application, and package as a Docker image
	docker build --file nft/Dockerfile --tag $(REGISTRY)/$(FAST_FEEDBACK_PATH)/$(image_name)-nft:$(image_tag) .

.PHONY: push-functional
push-functional: ## Push the Functional Docker image to an image registry
	docker image push $(REGISTRY)/$(FAST_FEEDBACK_PATH)/$(image_name)-functional:$(image_tag)

.PHONY: push-nft
push-nft: ## Push the NFT Docker image to an image registry
	docker image push $(REGISTRY)/$(FAST_FEEDBACK_PATH)/$(image_name)-nft:$(image_tag)

.PHONY: deploy-functional
deploy-functional: ## Deploy helm chart of the reference app to functional namespace
	helm upgrade --install $(app_name)-dependencies ./helm-charts/ref-app-dependencies -n $(app_name)-functional --set registry=$(REGISTRY)/$(FAST_FEEDBACK_PATH) --atomic
	helm upgrade --install $(app_name) ./helm-charts/ref-app -n $(app_name)-functional --set registry=$(REGISTRY)/$(FAST_FEEDBACK_PATH) --set domain=$(BASE_DOMAIN) --set appUrlSuffix="-functional" --set tag=$(image_tag) --atomic
	helm list -n $(app_name)-functional ## list installed charts in the given tenant namespace

.PHONY: deploy-nft
deploy-nft:  ## Deploy helm chart of the reference app to nft namespace
	helm upgrade --install $(app_name)-dependencies ./helm-charts/ref-app-dependencies -n $(app_name)-nft --set registry=$(REGISTRY)/$(FAST_FEEDBACK_PATH) --atomic
	helm upgrade --install $(app_name) ./helm-charts/ref-app -n $(app_name)-nft --set registry=$(REGISTRY)/$(FAST_FEEDBACK_PATH) --set domain=$(BASE_DOMAIN) --set appUrlSuffix="-nft" --set tag=$(image_tag) --atomic
	helm list -n $(app_name)-nft ## list installed charts in the given tenant namespace

.PHONY: deploy-prod
deploy-prod: ## Deploy helm chart of the reference app to production namespace
	@echo $(image_tag)
	@echo $(REGISTRY)/release
	helm upgrade --install $(app_name)-dependencies ./helm-charts/ref-app-dependencies -n $(app_name) --set registry=$(REGISTRY)/$(PROD_PATH) --atomic
	helm upgrade --install $(app_name) ./helm-charts/ref-app -n $(app_name) --set registry=$(REGISTRY)/$(PROD_PATH) --set domain=$(BASE_DOMAIN)  --set tag=$(image_tag) --atomic
	helm list -n $(app_name) ## list installed charts in the given tenant namespace

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