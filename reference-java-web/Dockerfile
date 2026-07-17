FROM docker.io/gradle:9.6.1-jdk26-noble@sha256:99c063efb38fd59e628c1f67273fb270ef48f6c7a3741baed4165e72a944f3cd AS build
WORKDIR /build

COPY settings.gradle .
COPY service service

RUN gradle service:build --no-daemon

FROM docker.io/eclipse-temurin:26.0.1_8-jre-noble
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
  tar=1.35+dfsg-3ubuntu0.3 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/service/build/libs/service-*-SNAPSHOT.jar /service.jar
COPY service/src/main/resources/application.yaml /application.yaml

CMD ["java", "-jar", "service.jar"]

EXPOSE 8080 8081
