FROM docker.io/golang:1.27.1-alpine3.24 AS build
WORKDIR $GOPATH/src/go.k6.io/k6

# hadolint ignore=DL3018
RUN apk add --no-cache git && \
    go install go.k6.io/xk6@v1.4.14 && \
    xk6 build v1.8.1 \
      --replace github.com/gorilla/schema=github.com/gorilla/schema@v1.4.1 \
      --replace golang.org/x/crypto=golang.org/x/crypto@v0.57.0 \
      --replace google.golang.org/grpc=google.golang.org/grpc@v1.83.2 \
      --with github.com/coreeng/xk6-prometheus@v1.0.2 \
      --output /tmp/k6

FROM docker.io/alpine:3.24.2

# hadolint ignore=DL3018
RUN apk add --no-cache ca-certificates curl jq && \
    adduser -D -u 12345 -g 12345 k6

COPY --from=build /tmp/k6 /usr/bin/k6

USER 12345
WORKDIR /home/k6

COPY ./resources/load-testing/ /home/k6/load-testing

ENV K6_OUT=prometheus

ENTRYPOINT ["k6"]
