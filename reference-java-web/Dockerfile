FROM docker.io/gradle:9.8.0-jdk26-noble@sha256:7168b9b65175d776d2a186d23647383625284f9ec7df59873a47d9be0d1b58e7 AS build
WORKDIR /build

COPY settings.gradle .
COPY service service

RUN gradle service:build --no-daemon

FROM docker.io/eclipse-temurin:26.0.2.1_1-jre-noble
WORKDIR /

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
  gzip=1.12-1ubuntu3.2 \
  libgcrypt20=1.10.3-2ubuntu0.2 \
  libgnutls30t64=3.8.3-1.1ubuntu3.6 \
  liblzma5=5.6.1+really5.4.5-1ubuntu0.3 \
  libncursesw6=6.4+20240113-1ubuntu2.2 \
  libssl3t64=3.0.13-0ubuntu3.15 \
  libsystemd0=255.4-1ubuntu8.17 \
  libtinfo6=6.4+20240113-1ubuntu2.2 \
  libudev1=255.4-1ubuntu8.17 \
  ncurses-base=6.4+20240113-1ubuntu2.2 \
  ncurses-bin=6.4+20240113-1ubuntu2.2 \
  openssl=3.0.13-0ubuntu3.15 \
  perl-base=5.38.2-3.2ubuntu0.6 \
  tar=1.35+dfsg-3ubuntu0.4 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/service/build/libs/service-*-SNAPSHOT.jar /service.jar
COPY service/src/main/resources/application.yaml /application.yaml

CMD ["java", "-jar", "service.jar"]

EXPOSE 8080 8081
