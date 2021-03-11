FROM ruby:3.0.0-buster AS build
COPY zpcc /app
WORKDIR /app
RUN bundle install \
    && jekyll build

FROM nginx:1.19.7-alpine AS final
COPY --from=build /app/_site /usr/share/nginx/html
