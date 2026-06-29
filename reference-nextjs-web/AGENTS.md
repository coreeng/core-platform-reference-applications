# AGENTS.md - reference-nextjs-web

## Template And Tech Stack

This repository was generated from the Core Platform `nextjs-web` software template. It is a Next.js application using React and TypeScript, serves application traffic on port `3000`, exposes metrics on port `8081`, and deploys with the `core-platform-assets/core-platform-app` Helm chart.

## Core Platform P2P

Core Platform Path to Production (P2P) is driven by GitHub Actions workflows in `.github/workflows/` and Make targets in `Makefile`. The workflows delegate to reusable workflows from `coreeng/p2p` and the Makefile downloads `p2p.mk` from the same versioned P2P contract.

### Workflows

- `fast-feedback.yaml` runs on pushes, pull requests, and manual dispatch. It creates a version, builds the app image, deploys the functional stage, and runs functional checks.
- `extended-test.yaml` runs on schedule or manual dispatch. It finds the latest extended-test candidate image and runs the extended-test workflow.
- `prod.yaml` runs on schedule or manual dispatch. It finds the latest production candidate image and deploys production.
- `scheduled-security-scan.yaml` runs the generated repository's scheduled security scan.

### Stages

- Build creates and pushes the application image using the version produced by P2P.
- Functional deploys the app to the functional namespace and runs functional tests as Helm tests.
- Non-functional tests deploy the app to the NFT namespace and run K6 load tests as Helm tests when the NFT target is enabled.
- Integration deploys the app to the integration namespace and runs integration tests as Helm tests.
- Extended tests deploy the promoted image to the extended-test namespace and run longer-running validation.
- Prod deploys the selected production candidate to the production namespace.

### Configuration

- `p2p/config/common.yaml` contains Helm values shared by all stages. It is rendered with environment variables before Helm receives it.
- `p2p/config/functional.yaml` contains functional-stage overrides.
- `p2p/config/nft.yaml` contains NFT-stage overrides.
- `p2p/config/integration.yaml` contains integration-stage overrides.
- `p2p/config/extended-test.yaml` contains extended-test-stage overrides.
- `p2p/config/prod.yaml` contains production overrides.
- Stage-specific files should only contain differences from `common.yaml`.

### Tests

- Unit and lint checks run before the app image is built.
- Functional tests live in `p2p/tests/functional/` and validate externally visible app behavior with Cucumber and Playwright.
- Non-functional tests live in `p2p/tests/nft/` and use K6 plus Prometheus validation for load-test thresholds.
- Integration tests live in `p2p/tests/integration/` and validate behavior against deployed dependencies.
- Extended tests live in `p2p/tests/extended/` and are intended for longer or higher-load validation than fast feedback.

Keep generated P2P contract changes aligned across `Makefile`, `.github/workflows/`, `p2p/config/`, and `p2p/tests/`.
