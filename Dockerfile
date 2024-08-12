# syntax=docker/dockerfile:1
ARG HUGO_VERSION=0.131.0
ARG NGINX_VERSION=1.27.0

# ---

FROM hugomods/hugo:exts-${HUGO_VERSION} AS build

ARG MODE=development
ARG VERSION=dev
ENV HUGO_PARAMS_VERSION=${VERSION}

COPY . /work
WORKDIR /work

RUN hugo --environment=${MODE} --minify

# ---

FROM nginx:${NGINX_VERSION}-alpine AS final
COPY --from=build /work/public /usr/share/nginx/html
