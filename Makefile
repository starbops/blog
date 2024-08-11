
IMG ?= blog:dev

CONTAINER_TOOL ?= docker

SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAG = -ec

.PHONY: all
all: lint build

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: lint
lint: ## Analyze potential syntax and style issues.
	@echo "Preparing..."
	docker build -t mdl:latest . -f Dockerfile.lint
	@echo "Linting..."
	docker run --rm mdl:latest

.PHONY: build
build: ## Build artifacts from source.
	@echo "Building..."
	hugo --environment=development

.PHONY: run
run: lint ## Run a web server locally
	@echo "Running..."
	hugo --environment=development server

.PHONY: docker-build
docker-build: ## Build from source and package built artifacts into container image.
	@echo "Packaging..."
	$(CONTAINER_TOOL) build -t ${IMG} .

.PHONY: docker-push
docker-push: ## Push docker image.
	$(CONTAINER_TOOL) push ${IMG}

PLATFORMS ?= linux/amd64,linux/arm64
.PHONY: docker-buildx
docker-buildx: ## Build from source and package built artifacts into container image for cross-platform support.
	- $(CONTAINER_TOOL) buildx create --name hugo-builder
	$(CONTAINER_TOOL) buildx use hugo-builder
	@echo "Packaging..."
	- $(CONTAINER_TOOL) buildx build --push --platform=$(PLATFORMS) --tag ${IMG} .
	- $(CONTAINER_TOOL) buildx rm hugo-builder

.PHONY: clean
clean: ## Clean up built artifacts.
	@echo "Cleaning..."
	@\rm -vrf public/ resources/
