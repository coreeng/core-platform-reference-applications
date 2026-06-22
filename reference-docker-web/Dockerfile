FROM docker.io/stefanprodan/podinfo:6.14.0

USER root

RUN apk add --no-cache libcrypto3=3.5.7-r0 libssl3=3.5.7-r0

USER app

EXPOSE 9898
