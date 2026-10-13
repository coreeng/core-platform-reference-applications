FROM docker.io/stefanprodan/podinfo:6.15.0

USER 0

# Alpine replaces package revisions in its repositories, so exact pins can break builds.
# Apply available updates from the base image's configured Alpine release repositories.
RUN apk upgrade --no-cache

USER 100:101

EXPOSE 8080

CMD ["./podinfo", "--port=8080"]
