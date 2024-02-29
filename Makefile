export OSTYPE = $(shell uname)

log: ## install log module
	kubectl apply -k ./logging

flink: ## install flink module
	kubectl apply -k ./flink-system

calico: ## install calico module
	kubectl apply -k ./calico-system

elastic: ## install elastic module
	kubectl apply -k ./elastic-system

redis: ## install redis module
	kubectl apply -k ./redis-system

istio: ## install istio module
	kubectl apply -k ./istio-system

flux: ## install flux module
	kubectl apply -k ./flux-system

debug: ## install debuging
	kubectl run -i --tty temp -n redis-system --image=busybox --restart=Never -- sh

uninstall: ## uninstall all modules
	kubectl delete -k .

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.DEFAULT_GOAL := help
