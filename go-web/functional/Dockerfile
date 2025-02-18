FROM golang:1.24-alpine3.21

# hadolint ignore=DL3018
RUN apk --no-cache add build-base && \
    go install github.com/cucumber/godog/cmd/godog@v0.12.6

COPY ./functional/ /opt/app
WORKDIR /opt/app

CMD ["godog"]
