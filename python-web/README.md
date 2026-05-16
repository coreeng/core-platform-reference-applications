# python-web

Python web application for Core Platform

## Overview

The service exposes two ports:

| Port | Purpose |
|------|---------|
| 8080 | Application traffic (`GET /hello`) |
| 8081 | Internal/ops traffic (`GET /metrics`, `GET /internal/status`) |

## P2P Overview

The Path to Production (P2P) pipeline progresses through these namespaces:

| Stage | Namespace | Triggered by |
|-------|-----------|-------------|
| Fast Feedback | `python-web-functional` | Push / PR to `main` |
| NFT | `python-web-nft` | Fast Feedback |
| Integration | `python-web-integration` | Fast Feedback |
| Extended Test | `python-web-extended-test` | Daily schedule (22:00 UTC) |
| Prod | `python-web-prod` | Weekday schedule (05:30 UTC) |

## Local Development

### Prerequisites

- [uv](https://docs.astral.sh/uv/) — Python package manager
- Python 3.13+
- Docker (for building and running containers)

### Setup

```bash
uv sync
```

### Run locally

```bash
uv run python -m app.main
```

The service will be available at:
- `http://localhost:8080/hello`
- `http://localhost:8081/internal/status`
- `http://localhost:8081/metrics`

### Run unit tests

```bash
uv run pytest
```

### Lint

```bash
uv run ruff check src/ tests/
```

## Image Versioning

Images are versioned automatically by the P2P pipeline using the commit SHA. To build and run locally:

```bash
export VERSION=local
export REGISTRY=localhost
make build-app
make run-app
```

> **ARM64 note:** On Apple Silicon, set `DOCKER_DEFAULT_PLATFORM=linux/amd64` to build images compatible with the cluster.

## Testing

### Functional Tests

BDD tests using [Behave](https://behave.readthedocs.io/) (Python Cucumber). They run against the deployed service in the `functional` namespace.

```bash
make p2p-functional
```

Feature files are in `p2p/tests/functional/features/`.

### NFT (Non-Functional Tests)

Load tests using [K6](https://k6.io/). Default target: 1,000 req/s for 1 minute with P99 < 2000ms.

```bash
make p2p-nft
```

Scripts are in `p2p/tests/nft/resources/load-testing/`.

### Integration Tests

BDD tests that run against real downstream dependencies in the `integration` namespace.

```bash
make p2p-integration
```

### Extended Tests

Higher-load / longer-running tests scheduled nightly. Placeholder — implement as needed.

## Platform Features

### Monitoring

Prometheus metrics are exposed on port 8081 at `/metrics`. The Helm chart configures scraping automatically when `metrics.enabled: true`.

### Dashboarding

A Grafana dashboard is available via the internal services domain once the app is deployed. Log links are printed at the end of each test run.

### K6 Operator

The NFT and Extended test stages use the K6 Operator on the cluster. The custom K6 build includes the [xk6-prometheus](https://github.com/coreeng/xk6-prometheus) extension so metrics are exported to Prometheus during load tests.
