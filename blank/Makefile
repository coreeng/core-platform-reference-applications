projectDir := $(realpath $(dir $(firstword $(MAKEFILE_LIST))))
os := $(shell uname)
image_tag = $(VERSION)
image_name = blank-app
tenant_name = $(TENANT_NAME)

FAST_FEEDBACK_PATH = fast-feedback
EXTENDED_TEST_PATH = extended-test
PROD_PATH = prod

# P2P tasks

.PHONY: p2p-image
p2p-image:
	@echo $(image_name)

.PHONY: p2p-build
p2p-build: 
	docker build --file Dockerfile --tag $(REGISTRY)/$(FAST_FEEDBACK_PATH)/$(image_name):$(image_tag) .
	docker image push $(REGISTRY)/$(FAST_FEEDBACK_PATH)/$(image_name):$(image_tag)

.PHONY: p2p-functional
p2p-functional: 

.PHONY: p2p-nft
p2p-nft:

.PHONY: p2p-integration
p2p-integration:

.PHONY: p2p-extended-test
p2p-extended-test:  
	
.PHONY: p2p-prod
p2p-prod: 

.PHONY: p2p-promote-generic
p2p-promote-generic:  ## Generic promote functionality
	corectl p2p promote $(image_name):${image_tag} \
    		--source-stage $(source_repo_path) \
    		--dest-registry $(REGISTRY) \
    		--dest-stage $(dest_repo_path)


.PHONY: p2p-promote-to-extended-test
p2p-promote-to-extended-test: source_repo_path=$(FAST_FEEDBACK_PATH)
p2p-promote-to-extended-test: dest_repo_path=$(EXTENDED_TEST_PATH)
p2p-promote-to-extended-test:  p2p-promote-generic

.PHONY: p2p-promote-to-prod
p2p-promote-to-prod:  source_repo_path=$(EXTENDED_TEST_PATH)
p2p-promote-to-prod:  dest_repo_path=$(PROD_PATH)
p2p-promote-to-prod:  p2p-promote-generic