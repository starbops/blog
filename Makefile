JEKYLL_ENV ?= development
VERSION ?= v0.1.0

test:
	docker build -t mdl:latest . -f Dockerfile.lint
	docker run --rm mdl:latest
build:
	docker build --build-arg JEKYLL_ENV=$(JEKYLL_ENV) --build-arg VERSION=$(VERSION:v%=%) -t blog:$(VERSION) .
run:
	docker run --rm -p 8080:80 blog:$(VERSION)
