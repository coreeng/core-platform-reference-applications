FROM gradle:8.14.0-jdk21

WORKDIR /opt/app

COPY build.gradle settings.gradle ./
COPY src ./src

ENTRYPOINT ["gradle"]
CMD ["--no-daemon", "clean", "test"]
