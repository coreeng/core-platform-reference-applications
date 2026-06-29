# reference-go-web

Go web application generated from the Core Platform `go-web` software template.

## Tech Stack

- Go web service using Gin.
- Container image built from the generated `Dockerfile`.
- Application traffic is served on port `8080`.
- Operational endpoints are served on port `8081`.

## Application Endpoints

- `GET /hello` returns a simple hello response.
- `GET /internal/status` reports application health.
- `GET /metrics` exposes Prometheus metrics.

## Project Layout

- `cmd/service/` contains the service entry point.
- `cmd/handler/` contains HTTP handlers.
- `p2p/` contains Core Platform deployment config and test containers.
- `AGENTS.md` contains generated-repository guidance for coding agents.
