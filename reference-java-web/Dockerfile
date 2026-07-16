FROM docker.io/gradle:9.5.1-jdk25-noble@sha256:41efb76abd9146b76866f80a09deedde16cef5138394324a332a52d944e71b15 AS build
WORKDIR /build

COPY settings.gradle .
COPY service service

RUN gradle service:build --no-daemon

FROM docker.io/eclipse-temurin:25.0.3_9-jre-noble
WORKDIR /

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
  gzip=1.12-1ubuntu3.2 \
  libgcrypt20=1.10.3-2ubuntu0.1 \
  libgnutls30t64=3.8.3-1.1ubuntu3.6 \
  liblzma5=5.6.1+really5.4.5-1ubuntu0.3 \
  libncursesw6=6.4+20240113-1ubuntu2.1 \
  libssl3t64=3.0.13-0ubuntu3.11 \
  libsystemd0=255.4-1ubuntu8.16 \
  libtinfo6=6.4+20240113-1ubuntu2.1 \
  libudev1=255.4-1ubuntu8.16 \
  ncurses-base=6.4+20240113-1ubuntu2.1 \
  ncurses-bin=6.4+20240113-1ubuntu2.1 \
  openssl=3.0.13-0ubuntu3.11 \
  perl-base=5.38.2-3.2ubuntu0.3 \
  tar=1.35+dfsg-3ubuntu0.2 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/service/build/libs/service-*-SNAPSHOT.jar /service.jar
COPY service/src/main/resources/application.yaml /application.yaml

CMD ["java", "-jar", "service.jar"]

EXPOSE 8080 8081
