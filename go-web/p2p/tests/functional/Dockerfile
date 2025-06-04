FROM golang:1.24.3-alpine3.22 AS builder

# hadolint ignore=DL3018
RUN apk --no-cache add build-base && \
    go install github.com/cucumber/godog/cmd/godog@v0.12.6

COPY ./ /opt/app
WORKDIR /opt/app

CMD ["godog"]
