FROM golang:1.22-alpine AS build

ARG MODE=development
ARG VERSION=dev
ENV HUGO_PARAMS_VERSION=${VERSION}

COPY . /work
WORKDIR /work

RUN go install github.com/gohugoio/hugo@v0.131.0 && \
    hugo --environment=${MODE} --minify

# ---

FROM nginx:1.27.0-alpine AS final
COPY --from=build /work/public /usr/share/nginx/html
