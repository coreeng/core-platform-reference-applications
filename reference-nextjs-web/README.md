# reference-nextjs-web

Next.js web application generated from the Core Platform `nextjs-web` software template.

## Tech Stack

- Next.js application using React and TypeScript.
- Yarn-managed JavaScript dependencies.
- Container image built from the generated `Dockerfile`.
- Application traffic is served on port `3000`.
- Metrics are served on port `8081`.

## Application Endpoints

- `GET /` serves the application home page.
- `GET /readyz` reports readiness.
- `GET /livez` reports liveness.
- `GET /metrics` exposes Prometheus metrics.

## Project Layout

- `src/app/` contains the Next.js app router pages and route handlers.
- `src/lib/` contains shared runtime support.
- `p2p/` contains Core Platform deployment config and test containers.
- `AGENTS.md` contains generated-repository guidance for coding agents.
