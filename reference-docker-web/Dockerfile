FROM docker.io/stefanprodan/podinfo:6.14.0

USER 0

RUN apk add --no-cache \
    c-ares=1.34.8-r0 \
    curl=8.22.0-r0 \
    libcrypto3=3.5.8-r0 \
    libcurl=8.22.0-r0 \
    libssl3=3.5.8-r0

USER 100:101

EXPOSE 9898
