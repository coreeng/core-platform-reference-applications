# The Gradle JDK 25 image publishes the distribution for all supported architectures.
FROM docker.io/gradle:9.9.2-jdk25-resolute@sha256:a16370cdf4fab2bdec80810ba7f7d577fc2ce86eb1332b067031fcc19d947ed5 AS gradle-dist

FROM docker.io/eclipse-temurin:27.0.1.0-jdk-resolute@sha256:653c788ead947fce2b3452b434f25f69adf9b60c9f41e4639b3592caa719f683 AS build
COPY --from=gradle-dist /opt/gradle /opt/gradle
ENV PATH="/opt/gradle/bin:${PATH}"
WORKDIR /build

COPY settings.gradle .
COPY service service

RUN gradle service:build --no-daemon

FROM docker.io/eclipse-temurin:27.0.1.0-jre-resolute
WORKDIR /

# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install --no-install-recommends -y \
  gzip \
  libgcrypt20 \
  libgnutls30t64 \
  liblzma5 \
  libncursesw6 \
  libssl3t64 \
  libsystemd0 \
  libtinfo6 \
  libudev1 \
  ncurses-base \
  ncurses-bin \
  openssl \
  perl-base \
  tar \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/service/build/libs/service-*-SNAPSHOT.jar /service.jar
COPY service/src/main/resources/application.yaml /application.yaml

CMD ["java", "-jar", "service.jar"]

EXPOSE 8080 8081
