FROM docker.io/gradle:9.9.1-jdk27-resolute@sha256:b10e6aa52100d96fd9cd376a2b27082372a0e99f1fd5bdd0fc6a74b0100d423a AS build
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
