FROM docker.io/gradle:9.9.1-jdk27-resolute@sha256:b10e6aa52100d96fd9cd376a2b27082372a0e99f1fd5bdd0fc6a74b0100d423a

WORKDIR /opt/app

COPY build.gradle settings.gradle ./
COPY src ./src

ENTRYPOINT ["gradle"]
CMD ["--no-daemon", "clean", "test"]
