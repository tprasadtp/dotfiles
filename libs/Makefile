SHELL := /bin/bash
.DEFAULT_GOAL := help
export REPO_ROOT := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.PHONY: help
help: ### This help message
	@printf "%-20s %s\n" "Target" "Help"
	@printf "%-20s %s\n" "-----" "-----"
	@grep -E '^[a-zA-Z_-]+:.*?### .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?### "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: clean
clean: ### Cleanup docker images
	@docker images --filter label=io.github.tprasadtp.shlib-test-image=true --format "{{.Repository}}:{{ .Tag }}" | xargs --no-run-if-empty docker rmi
