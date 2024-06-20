FROM gradle:8.6.0-jdk21 AS build
WORKDIR /build/
COPY . /build/

RUN gradle service:bootJar

FROM registry.access.redhat.com/ubi8/openjdk-21
WORKDIR /
COPY --from=build /build/service/build/libs/service-*-SNAPSHOT.jar /service.jar
COPY service/application.yaml /application.yaml

CMD ["java", "-jar", "service.jar"]