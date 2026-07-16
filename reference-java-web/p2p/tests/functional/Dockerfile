FROM docker.io/gradle:9.5.1-jdk25-noble@sha256:41efb76abd9146b76866f80a09deedde16cef5138394324a332a52d944e71b15

WORKDIR /opt/app

COPY build.gradle settings.gradle ./
COPY src ./src

ENTRYPOINT ["gradle"]
CMD ["--no-daemon", "clean", "test"]
