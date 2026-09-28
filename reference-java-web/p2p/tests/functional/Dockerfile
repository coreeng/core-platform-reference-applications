FROM docker.io/gradle:9.8.0-jdk26-noble@sha256:7168b9b65175d776d2a186d23647383625284f9ec7df59873a47d9be0d1b58e7

WORKDIR /opt/app

COPY build.gradle settings.gradle ./
COPY src ./src

ENTRYPOINT ["gradle"]
CMD ["--no-daemon", "clean", "test"]
