FROM gradle:jdk21 AS build
WORKDIR /build/
COPY . .

RUN gradle service:build --no-daemon

FROM registry.access.redhat.com/ubi8/openjdk-21
WORKDIR /
COPY --from=build /build/service/build/libs/service-*-SNAPSHOT.jar /service.jar
COPY service/src/main/resources/application.yaml /application.yaml

CMD ["java", "-jar", "service.jar"]
