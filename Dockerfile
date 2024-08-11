FROM golang:1.22-alpine AS build
ARG MODE=development
ARG VERSION=dev
ENV HUGO_PARAMS_VERSION=${VERSION}

COPY . /work
WORKDIR /work

# Install Hugo
RUN apk add build-base; \
    CGO_ENABLED=1 go install -tags extended github.com/gohugoio/hugo@latest

# Build
RUN hugo --environment=${MODE}

FROM nginx:1.27.0-alpine AS final
COPY --from=build /work/public /usr/share/nginx/html
