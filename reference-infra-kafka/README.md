# reference-infra-kafka

Infrastructure provisioning application for Core Platform GCP Managed Service for Apache Kafka.

This repository is generated with the Kafka template. Before the Path to Production workflows can provision anything, fill in the GCP projects, connected platform subnet, client service account, topics, and ACLs under `p2p/config/`.

## Required Configuration

Collect these values before enabling the pipeline:

| Field | Integration | Prod |
|---|---|---|
| Infra project ID | GCP project where integration Kafka clusters and Terraform state are created | GCP project where production Kafka clusters and Terraform state are created |
| Platform project ID | Core Platform project where the consuming GKE pods run | Core Platform production project where the consuming GKE pods run |
| Region | GCP region for Kafka, connected subnets, and Terraform state, for example `europe-west2` | Same region unless production needs a different location |
| Connected subnet | Subnet in the platform/GKE VPC that Managed Kafka connects to | Production platform/GKE subnet |
| Kafka cluster name | Kafka cluster base name | Usually the same value as integration |
| App service account email | Cloud access GCP service account used by the application pods | Production cloud access GCP service account |
| Topics and ACLs | Kafka topics and authorizations required by the application | Production topics and authorizations |

## Network Connectivity

The Kafka cluster is created in `infrastructure_project_id`, but the pods connect through a subnet in `platform_project_id`.

Managed Kafka creates Private Service Connect endpoints and DNS records automatically in each connected VPC network. This template does not create PSC endpoints directly; it attaches the configured subnets to the Kafka cluster.

Pods can connect when:

- The cluster has a connected subnet from the platform/GKE VPC.
- The connected subnet is in the same region as the Kafka cluster.
- The Kafka service agent from the infra project has `roles/managedkafka.serviceAgent` on the platform project.
- Egress to Kafka port `9092` is allowed by platform network policy and firewall rules.
- Pods use the bootstrap address reported by Managed Kafka after the cluster is created.

## Authentication And Authorization

Application pods should use their Core Platform cloud access GCP service account for IAM-backed Kafka broker authentication.

The template grants each configured `client_principals` entry `roles/managedkafka.client` in the infra project. Kafka ACLs are configured separately and authorize operations on Kafka resources such as topics and consumer groups.

For service account clients, use:

```text
client_principals: serviceAccount:<service-account-email>
Kafka ACL principal: User:<service-account-email>
```

## Configure Common Values

Set values shared by all stages in `p2p/config/common.yaml`:

```yaml
---
region: europe-west2

kafka:
  enabled: true
  clusters:
    - name: my-app
      vcpu_count: 3
      memory_bytes: 3221225472
      connected_subnets:
        - project_id: core-platform-dev
          subnet: projects/core-platform-dev/regions/europe-west2/subnetworks/gke-workloads
          grant_service_agent_role: true
      client_principals:
        - serviceAccount:my-app-ca@core-platform-dev.iam.gserviceaccount.com
      topics:
        - name: events
          partition_count: 3
          replication_factor: 3
          configs:
            cleanup.policy: delete
      acls:
        - id: topic/events
          entries:
            - principal: User:my-app-ca@core-platform-dev.iam.gserviceaccount.com
              operation: ALL
              permission_type: ALLOW
              host: "*"
        - id: consumerGroup/my-app
          entries:
            - principal: User:my-app-ca@core-platform-dev.iam.gserviceaccount.com
              operation: ALL
              permission_type: ALLOW
              host: "*"
```

## Configure Stage Projects

Set project IDs in every stage that should deploy Kafka. The generated template includes these files:

- `p2p/config/functional.yaml`
- `p2p/config/integration.yaml`
- `p2p/config/nft.yaml`
- `p2p/config/extended-test.yaml`
- `p2p/config/prod.yaml`

Example:

```yaml
---
infrastructure_project_id: my-app-dev-infra
platform_project_id: core-platform-dev
```

Terragrunt skips provisioning until all required bootstrap values are present:

- `region`
- `infrastructure_project_id`
- `platform_project_id`

Kafka resources are only created when `kafka.enabled` is `true` and at least one cluster is configured.
