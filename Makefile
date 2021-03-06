.PHONY: help

APP_NAME ?= backend
APP_VSN ?= `grep 'version:' mix.exs | cut -d '"' -f2`
BUILD ?= `git rev-parse --short HEAD`

help:
		@echo "$(APP_NAME):$(APP_VSN)$(BUILD)"
		@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image
		docker build --build-arg APP_NAME=$(APP_NAME) \
				--build-arg APP_VSN=$(APP_VSN) \
				-t "reetou/$(APP_NAME):$(APP_VSN)-$(BUILD)" \
				-t reetou/$(APP_NAME):latest .

run: ## Run the app in Docker
		docker run --env-file config/docker.env \
				-P \
				--rm -it reetou/$(APP_NAME):latest /opt/app/bin/bot foreground
