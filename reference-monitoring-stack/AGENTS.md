# AGENTS.md - reference-monitoring-stack

## Template And Tech Stack

This repository was generated from the Core Platform `monitoring-stack` software template. It deploys the `core-platform-assets/core-platform-monitoring` Helm chart, which provides Prometheus, Grafana, and Alertmanager for a delivery unit.

## Core Platform P2P

Core Platform Path to Production (P2P) is driven by GitHub Actions workflows in `.github/workflows/` and Make targets in `Makefile`. This template is deploy-oriented: it builds a lightweight runner image, deploys the monitoring chart, and validates the integration deployment.

### Workflows

- `fast-feedback.yaml` creates a version and builds the generated image.
- `extended-test.yaml` exists for the standard repository workflow set, but this template's active validation is integration-focused.
- `prod.yaml` finds the selected production candidate and deploys production.
- `scheduled-security-scan.yaml` runs the generated repository's scheduled security scan.

### Stages

- Build creates and pushes the generated image using the version produced by P2P.
- Integration deploys the monitoring chart to the integration namespace and runs the integration validation container.
- Prod deploys the selected production candidate to the production namespace.

### Configuration

- `p2p/config/common.yaml` contains Helm values shared by monitoring deployments.
- `p2p/config/integration.yaml` lists integration namespaces and target instances to monitor.
- `p2p/config/prod.yaml` lists production namespaces and target instances to monitor.
- Add monitored delivery units by updating `prometheus.targetNamespaces` and `prometheus.targetInstances` in the stage-specific config file.

Keep generated P2P contract changes aligned across `Makefile`, `.github/workflows/`, `p2p/config/`, and `p2p/tests/`.
