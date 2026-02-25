FROM docker.io/golang:1.26.0-alpine3.23 AS build

# hadolint ignore=DL3018
RUN apk --no-cache add build-base && \
    go install github.com/cucumber/godog/cmd/godog@v0.15.1

COPY ./ /opt/app
WORKDIR /opt/app

CMD ["godog"]
