# reference-infra-cloudsql

Infrastructure provisioning application for Core Platform Cloud SQL.

This repository is generated with the Cloud SQL template, but the template cannot know which GCP projects, database names, service accounts, or alert recipients your team needs. Before the Path to Production workflows can provision anything, fill in the configuration under `p2p/config/`.

## Required Configuration

Collect these values before enabling the pipeline:

| Field | Integration | Prod |
|---|---|---|
| Infra project ID | GCP project where integration Cloud SQL resources and Terraform state are created | GCP project where production Cloud SQL resources and Terraform state are created |
| Platform project ID | Core Platform project for the integration environment that consumes the database | Core Platform project for the production environment that consumes the database |
| Region | GCP region for Cloud SQL and Terraform state, for example `europe-west2` | Same region unless production needs a different location |
| DB cluster name | Cloud SQL instance base name | Usually the same value as integration |
| DB name | PostgreSQL database name, usually named after the application tenant that will use it | Usually the same value as integration |
| App service account email | Cloud access GCP service account for the application tenant in the integration platform project | Cloud access GCP service account for the application tenant in the production platform project |
| Alert email groups | Email group or groups for Cloud SQL alert notifications | Email group or groups for Cloud SQL alert notifications |
| DB tier | Instance tier, for example `db-g1-small` for a small starting footprint | `db-g1-small` for a small starting footprint, or a larger tier if production load requires it |
| PostgreSQL version | PostgreSQL version, for example `POSTGRES_18` | Usually the same value as integration |

## Platform Project IDs vs Infra Project IDs

The template uses two project IDs:

- `platform_project_id`: the Core Platform environment project that runs applications connecting to the database.
- `infrastructure_project_id`: the tenant-owned GCP project where this template creates Cloud SQL, monitoring resources, and Terraform state.

The `infrastructure_project_id` project must already exist, have billing enabled, and allow the P2P deploy identity to manage resources. Terragrunt stores state in a bucket named `tfstate-<infrastructure_project_id>`.

## Cloud Access Service Account

Use the cloud access GCP service account for the application that connects to the database, not the P2P service account.

Core Platform derives the cloud access service account from the application tenant's `cloudAccess` entry:

```text
<application-tenant>-<cloud-access-name>@<platform-project-id>.iam.gserviceaccount.com
```

For the default cloud access name `ca`, an application tenant named `my-app` in platform project `core-platform-dev` uses:

```text
my-app-ca@core-platform-dev.iam.gserviceaccount.com
```

If the application tenant does not have `cloudAccess` configured, add it in the Core Platform environments repository before using the service account in this Cloud SQL configuration.

## Configure Common Values

Set values shared by all stages in `p2p/config/common.yaml`:

```yaml
---
region: europe-west2

cloudsql:
  enabled: true
  monitoring:
    notification_emails:
      - team-alerts@example.com
  clusters:
    postgresql:
      - name: my-app-infra
        tier: db-g1-small
        database_version: POSTGRES_18
        databases:
          - name: my-app
            iam_users:
              - id: my-app
                email: my-app-ca@core-platform-dev.iam.gserviceaccount.com
                roles:
                  - pg_read_all_data
                  - pg_write_all_data
```

## Configure Integration-Like Stages

Set the integration infra and platform projects in every non-prod stage that should deploy Cloud SQL. The generated template includes these files:

- `p2p/config/functional.yaml`
- `p2p/config/integration.yaml`
- `p2p/config/nft.yaml`
- `p2p/config/extended-test.yaml`

Example:

```yaml
---
infrastructure_project_id: my-app-dev-infra
platform_project_id: core-platform-dev
```

## Configure Prod

Set the production infra and platform projects in `p2p/config/prod.yaml`. If the application's cloud access service account email differs between integration and prod, override `cloudsql` in `prod.yaml` so the prod database grants access to the prod service account.

Example:

```yaml
---
infrastructure_project_id: my-app-prod-infra
platform_project_id: core-platform-prod

cloudsql:
  enabled: true
  monitoring:
    notification_emails:
      - team-alerts@example.com
  clusters:
    postgresql:
      - name: my-app-infra
        tier: db-g1-small
        database_version: POSTGRES_18
        databases:
          - name: my-app
            iam_users:
              - id: my-app
                email: my-app-ca@core-platform-prod.iam.gserviceaccount.com
                roles:
                  - pg_read_all_data
                  - pg_write_all_data
```

## When Provisioning Runs

Terragrunt skips provisioning until all required bootstrap values are present:

- `region`
- `infrastructure_project_id`
- `platform_project_id`

Cloud SQL resources are only created when `cloudsql.enabled` is `true` and at least one PostgreSQL cluster is configured.

## Network Defaults

Generated Cloud SQL instances use public IP by default with Cloud SQL connector enforcement enabled. Applications should connect through a Cloud SQL connector or Cloud SQL Auth Proxy, and access can be narrowed with `cloudsql.allowed_ip_ranges`.

Private networking is opt-in:

- Set `cloudsql.psa_enabled: true` to create a dedicated Private Service Access VPC and attach instances to it.
- Set `cloudsql.psc_enabled: true` to enable Private Service Connect producer-side settings for the platform project.
- Set cluster `public_ip_enabled: false` only when `cloudsql.psa_enabled` or `cloudsql.psc_enabled` is also enabled.
- Set `cloudsql.ids.enabled: true` only with `cloudsql.psa_enabled: true`; Cloud IDS mirrors the PSA VPC.

Do not enable PSC unless the consuming platform environment also provides the required PSC consumer endpoint and DNS. Without that platform-side setup, PSC-only clients cannot resolve or reach the Cloud SQL instance.
