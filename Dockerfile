FROM ruby:2.7.1-buster AS build
ARG JEKYLL_ENV=development
COPY blog /app
WORKDIR /app
RUN bundle install \
    && JEKYLL_ENV=${JEKYLL_ENV} bundle exec jekyll build

FROM nginx:1.19.7-alpine AS final
COPY ./nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/_site /usr/share/nginx/html
