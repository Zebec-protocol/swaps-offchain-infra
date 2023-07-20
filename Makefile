
SHELL := /bin/bash

.DEFAULT_GOAL := help

export APP_ROOT := $(shell 'pwd')

-include $(APP_ROOT)/Makefile.override

_build-and-push-keeper:
	@docker build $(APP_ROOT) \
		-f $(APP_ROOT)/docker/Dockerfile.prod \
		-t $(KEEPER_IMAGE_NAME) --target swaps-keeper
	@docker push $(KEEPER_IMAGE_NAME)


_build-and-push-liquidator:
	@docker build $(APP_ROOT) \
		-f $(APP_ROOT)/docker/Dockerfile.prod \
		-t $(LIQUIDATOR_IMAGE_NAME) --target swaps-liquidator
	@docker push $(LIQUIDATOR_IMAGE_NAME)


_build-and-push-order-keeper:
	@docker build $(APP_ROOT) \
		-f $(APP_ROOT)/docker/Dockerfile.prod \
		-t $(ORDER_KEEPER_IMAGE_NAME) --target swaps-order-keeper
	@docker push $(ORDER_KEEPER_IMAGE_NAME)


build-and-push-prod: _build-and-push-keeper _build-and-push-liquidator _build-and-push-order-keeper ## Build and push docker images to the registry


_update-keeper-argoconfig:
	@kubectl set image --filename k8s/dev/keeper-deployment.yaml keeper-app=$(KEEPER_IMAGE_NAME) --local -o yaml > new-deployment.yaml
	@cat new-deployment.yaml
	@rm -rf k8s/dev/keeper-deployment.yaml
	@mv new-deployment.yaml k8s/dev/keeper-deployment.yaml

_update-liquidator-argoconfig:
	@kubectl set image --filename k8s/dev/liquidator-deployment.yaml liquidator-app=$(LIQUIDATOR_IMAGE_NAME) --local -o yaml > new-deployment.yaml
	@cat new-deployment.yaml
	@rm -rf k8s/dev/liquidator-deployment.yaml
	@mv new-deployment.yaml k8s/dev/liquidator-deployment.yaml

_update-order-keeper-argoconfig:
	@kubectl set image --filename k8s/dev/order-keeper-deployment.yaml order-keeper-app=$(ORDER_KEEPER_IMAGE_NAME) --local -o yaml > new-deployment.yaml
	@cat new-deployment.yaml
	@rm -rf k8s/dev/order-keeper-deployment.yaml
	@mv new-deployment.yaml k8s/dev/order-keeper-deployment.yaml

update-argoconfig: _update-keeper-argoconfig _update-liquidator-argoconfig _update-order-keeper-argoconfig ## Update argo config with new image tag

deploy: build-and-push-prod update-argoconfig ## Deploy to kubernetes
	@echo "Completed!"

help:
	@echo -e "\n Usage: make [target]\n"
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-30s\033[0m %s\n", $$1, $$2}'
	@echo -e "\n"
