FROM docker.io/golang:1.27.4-alpine3.24 AS build
WORKDIR $GOPATH/src/go.k6.io/k6

# hadolint ignore=DL3018
RUN apk add --no-cache git && \
    go install go.k6.io/xk6@v1.5.1 && \
    xk6 build v1.8.3 \
      --replace github.com/gorilla/schema=github.com/gorilla/schema@v1.4.1 \
      --replace golang.org/x/crypto=golang.org/x/crypto@v0.59.0 \
      --replace google.golang.org/grpc=google.golang.org/grpc@v1.85.0 \
      --replace go.opentelemetry.io/otel/sdk=go.opentelemetry.io/otel/sdk@v1.47.0 \
      --replace go.opentelemetry.io/otel/trace=go.opentelemetry.io/otel/trace@v1.47.0 \
      --with github.com/coreeng/xk6-prometheus@v1.0.2 \
      --output /tmp/k6

FROM docker.io/alpine:3.24.4

RUN apk upgrade --no-cache

# hadolint ignore=DL3018
RUN apk add --no-cache ca-certificates curl jq && \
    adduser -D -u 12345 -g 12345 k6

COPY --from=build /tmp/k6 /usr/bin/k6

USER 12345
WORKDIR /home/k6

COPY ./resources/load-testing/ /home/k6/load-testing

ENV K6_OUT=prometheus

ENTRYPOINT ["k6"]
