FROM docker.io/stefanprodan/podinfo:6.14.0

USER root

RUN apk add --no-cache \
    c-ares=1.34.8-r0 \
    curl=8.20.0-r0 \
    libcrypto3=3.5.7-r0 \
    libcurl=8.20.0-r0 \
    libssl3=3.5.7-r0

USER app

EXPOSE 9898
