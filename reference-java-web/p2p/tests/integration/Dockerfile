FROM docker.io/gradle:9.6.1-jdk26-noble@sha256:99c063efb38fd59e628c1f67273fb270ef48f6c7a3741baed4165e72a944f3cd

WORKDIR /opt/app

COPY build.gradle settings.gradle ./
COPY src ./src

ENTRYPOINT ["gradle"]
CMD ["--no-daemon", "clean", "test"]
