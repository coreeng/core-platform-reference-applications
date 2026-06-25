FROM docker.io/gradle:9.5.1-jdk25-noble AS build
WORKDIR /build

COPY settings.gradle .
COPY service service

RUN gradle service:build --no-daemon

FROM eclipse-temurin:25-jre-noble
WORKDIR /

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
  libgcrypt20=1.10.3-2ubuntu0.1 \
  libgnutls30t64=3.8.3-1.1ubuntu3.6 \
  liblzma5=5.6.1+really5.4.5-1ubuntu0.3 \
  libssl3t64=3.0.13-0ubuntu3.11 \
  libsystemd0=255.4-1ubuntu8.16 \
  libudev1=255.4-1ubuntu8.16 \
  openssl=3.0.13-0ubuntu3.11 \
  perl-base=5.38.2-3.2ubuntu0.3 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/service/build/libs/service-*-SNAPSHOT.jar /service.jar
COPY service/src/main/resources/application.yaml /application.yaml

CMD ["java", "-jar", "service.jar"]

EXPOSE 8080 8081
