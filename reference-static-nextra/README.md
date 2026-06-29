# reference-static-nextra

Static documentation site generated from the Core Platform `static-nextra` software template.

## Tech Stack

- Nextra documentation site built on Next.js and React.
- Yarn-managed JavaScript dependencies.
- Container image built from the generated `Dockerfile`.
- Application traffic is served on port `3000`.
- Metrics are served on port `8081`.

## Application Endpoints

- `GET /` serves the documentation site.
- `GET /readyz` reports readiness.
- `GET /livez` reports liveness.
- `GET /metrics` exposes Prometheus metrics.

## Project Layout

- `src/app/` contains the Nextra application.
- `content/` contains documentation content.
- `p2p/` contains Core Platform deployment config and test containers.
- `AGENTS.md` contains generated-repository guidance for coding agents.
