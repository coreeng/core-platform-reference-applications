# reference-docker-web

Generic Docker web application generated from the Core Platform `docker-web` software template.

## Tech Stack

- Reference container image based on `stefanprodan/podinfo`.
- Container image built from the generated `Dockerfile`.
- Application traffic is served on port `9898`.

## Application Endpoints

- `GET /healthz` reports liveness.
- `GET /readyz` reports readiness.

## Project Layout

- `Dockerfile` defines the application image.
- `p2p/` contains Core Platform deployment config and test containers.
- `AGENTS.md` contains generated-repository guidance for coding agents.
