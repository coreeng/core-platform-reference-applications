FROM docker.io/gradle:9.8.1-jdk27-resolute@sha256:9e3408632d5c60581aebe1cace88d80de92213cd26e33d1a327a944b16a2d80d

WORKDIR /opt/app

COPY build.gradle settings.gradle ./
COPY src ./src

ENTRYPOINT ["gradle"]
CMD ["--no-daemon", "clean", "test"]
