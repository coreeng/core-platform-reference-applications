# reference-java-web

Java web application generated from the Core Platform `java-web` software template.

## Tech Stack

- Java Spring Boot web service.
- Gradle build with the generated Gradle wrapper.
- Container image built from the generated `Dockerfile`.
- Application traffic is served on port `8080`.
- Operational endpoints are served on port `8081`.

## Application Endpoints

- `GET /hello` returns a simple hello response.
- `GET /health` reports application health.
- `GET /prometheus` exposes Prometheus metrics.

## Project Layout

- `service/` contains the Spring Boot application.
- `p2p/` contains Core Platform deployment config and test containers.
- `AGENTS.md` contains generated-repository guidance for coding agents.
