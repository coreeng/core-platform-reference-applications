# reference-python-web

Python web application generated from the Core Platform `python-web` software template.

## Tech Stack

- Python FastAPI web service.
- `uv` for dependency management and local commands.
- Container image built from the generated `Dockerfile`.
- Application traffic is served on port `8080`.
- Operational endpoints are served on port `8081`.

## Application Endpoints

- `GET /hello` returns a simple hello response.
- `GET /internal/status` reports application health.
- `GET /metrics` exposes Prometheus metrics.

## Local Development

```bash
uv sync
uv run python -m app.main
```

Run unit tests with:

```bash
uv run pytest
```

Run lint checks with:

```bash
uv run ruff check src/ tests/
```

## Project Layout

- `src/app/` contains the FastAPI application.
- `tests/` contains unit tests.
- `p2p/` contains Core Platform deployment config and test containers.
- `AGENTS.md` contains generated-repository guidance for coding agents.
