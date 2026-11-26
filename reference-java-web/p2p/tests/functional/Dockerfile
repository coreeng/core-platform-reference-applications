# The Gradle JDK 25 image publishes the distribution for all supported architectures.
FROM docker.io/gradle:9.9.2-jdk25-resolute@sha256:a16370cdf4fab2bdec80810ba7f7d577fc2ce86eb1332b067031fcc19d947ed5 AS gradle-dist

FROM docker.io/eclipse-temurin:27.0.1.0-jdk-resolute@sha256:653c788ead947fce2b3452b434f25f69adf9b60c9f41e4639b3592caa719f683

# Gradle starts directly, so the inherited Pebble supervisor is unnecessary.
RUN apt-get update \
 && apt-get upgrade -y --no-install-recommends \
 && apt-get satisfy -y --no-install-recommends 'libexpat1 (>= 2.7.4-1ubuntu0.3)' \
 && rm -f /usr/bin/pebble \
 && rm -rf /var/lib/apt/lists/*

COPY --from=gradle-dist /opt/gradle /opt/gradle
ENV PATH="/opt/gradle/bin:${PATH}"

WORKDIR /opt/app

COPY build.gradle settings.gradle ./
COPY src ./src

ENTRYPOINT ["gradle"]
CMD ["--no-daemon", "clean", "test"]
