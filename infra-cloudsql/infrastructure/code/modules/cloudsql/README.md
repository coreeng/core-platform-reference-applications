# CloudSQL PostgreSQL Module

This module creates Google Cloud SQL PostgreSQL instances with comprehensive configuration options.

It wraps the official [terraform-google-sql-db PostgreSQL module](https://github.com/terraform-google-modules/terraform-google-sql-db/tree/main/modules/postgresql) with opinionated defaults and additional functionality.

## Module Features

- **Private Service Access (PSA)**: Automatic VPC network and PSA setup for private connectivity
- **Private Service Connect (PSC)**: Enabled for secure cross-project database access
- **High Availability**: Support for regional (HA) or zonal deployments
- **Comprehensive Backup**: Point-in-time recovery (PITR) with configurable retention
- **Security First**: Encrypted connections only, deletion protection by default
- **Query Insights**: Built-in query performance monitoring
- **IAM Integration**: Support for IAM-based database authentication
- **Multi-Database**: Support for multiple databases per instance

## Architecture

The module creates:
1. A dedicated VPC network for Cloud SQL Private Service Access
2. Private Service Access connection to Google Cloud SQL service producer
3. One or more PostgreSQL instances (defined via `for_each`)
4. Databases, users, and IAM bindings as configured

## Input Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `infrastructure_project_id` | `string` | GCP project ID where infrastructure resources (VPC, Cloud SQL) will be created |
| `platform_project_id` | `string` | GCP project ID for the platform that will consume the database via PSC |
| `environment` | `string` | Environment name (e.g., integration, prod) - used in resource naming |
| `region` | `string` | GCP region where resources will be created |

### CloudSQL Configuration

#### Core Settings

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enabled` | `bool` | (required) | Whether to create Cloud SQL resources |
| `allowed_ip_ranges` | `list(map(string))` | `[]` | List of authorized networks for public IP access. Each entry should have `name` and `value` (CIDR) |

#### Cluster Configuration

Each PostgreSQL cluster supports the following configuration:

##### Instance Identification

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `string` | (required) | The name of the Cloud SQL instance - full instance name will be `{name}-{environment}-cluster` |

##### Performance & Capacity

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `tier` | `string` | (required) | The tier for the Cloud SQL instance - e.g., `db-f1-micro`, `db-perf-optimized-N-8` |
| `database_version` | `string` | (required) | The database version to use - e.g., `POSTGRES_16`, `POSTGRES_17` |
| `edition` | `string` | `"ENTERPRISE"` | The edition of the Cloud SQL instance, can be either `ENTERPRISE` or `ENTERPRISE_PLUS` |
| `activation_policy` | `string` | `"ALWAYS"` | The activation policy for the Cloud SQL instance, can be either `ALWAYS` or `NEVER` |
| `data_cache_enabled` | `bool` | `false` | Whether data cache is enabled for the instance, only available for `ENTERPRISE_PLUS` tier and supported database_versions |

##### Database Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `databases` | `list(object)` | (required) | A list of databases to be create. Each object has:<br>• `name` - Database name<br>• `charset` - Character set (optional, default: `""`)<br>• `collation` - Collation (optional, default: `""`) |

##### Disk Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `disk_size` | `number` | `10` | The disk size in GB for the Cloud SQL instance |
| `disk_type` | `string` | `"PD_SSD"` | Disk type. Options:<br>• `PD_SSD` - SSD persistent disks<br>• `PD_HDD` - Standard persistent disks |
| `disk_autoresize` | `bool` | `true` | Wether to automatically increase disk size when needed |
| `disk_autoresize_limit` | `number` | `0` | The maximum size to which storage can be auto increased in GB (0 = unlimited) |

##### High Availability

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `availability_type` | `string` | `"ZONAL"` | The availability type for the Cloud SQL instance, can be either `ZONAL` or `REGIONAL` |

##### Backup Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `backup_configuration.enabled` | `bool` | `true` | Enable automated backups |
| `backup_configuration.start_time` | `string` | `"23:00"` | Backup start time in HH:MM format (UTC) |
| `backup_configuration.location` | `string` | `null` | Multi-region location for backups (e.g., `us`, `eu`). Default: same as instance region |
| `backup_configuration.point_in_time_recovery_enabled` | `bool` | `true` | Enable continuous backup for point-in-time recovery |
| `backup_configuration.transaction_log_retention_days` | `string` | `"7"` | Number of days to retain transaction logs for PITR (1-7 for PITR, up to 14 for Enterprise Plus) |
| `backup_configuration.retained_backups` | `number` | `15` | Number of backups to retain |
| `backup_configuration.retention_unit` | `string` | `"COUNT"` | Retention unit, can be `COUNT` or `TIME` |

##### Database Flags

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `database_flags` | `list(object)` | `[]` | The database flags for the Cloud SQL instance, [see more details](https://cloud.google.com/sql/docs/postgres/flags) |

##### Query Insights

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `insights_config.query_plans_per_minute` | `number` | `5` | Number of query plans to capture per minute |
| `insights_config.query_string_length` | `number` | `1024` | Maximum query string length to capture |
| `insights_config.record_application_tags` | `bool` | `false` | Record application tags in query insights |
| `insights_config.record_client_address` | `bool` | `false` | Record client IP addresses in query insights |

##### Maintenance Window

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `maintenance_window_day` | `number` | `1` | The day of week (1-7 where 1=Monday) for the Cloud SQL instance maintenance |
| `maintenance_window_hour` | `number` | `23` | The hour of day (0-23 UTC) maintenance window for the Cloud SQL instance maintenance |
| `maintenance_window_update_track` | `string` | `"stable"` | The update track of maintenance window for the Cloud SQL instance maintenance, can be either `canary` or `stable` |

##### Security & Deletion Protection

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `deletion_protection` | `bool` | `true` | Enables protection of an Cloud SQL instance from accidental deletion across all surfaces (API, gcloud, Cloud Console and Terraform) |
| `database_deletion_policy` | `string` | `"ABANDON"` | The deletion policy for the database, `ABANDON` is useful for PostgreSQL where databases cannot be deleted from the API if there are users other than cloudsqlsuperuser with access |
| `retain_backups_on_delete` | `bool` | `false` | When this parameter is set to true, Cloud SQL retains backups of the instance even after the instance is deleted. The ON_DEMAND backup will be retained until customer deletes the backup or the project. The AUTOMATED backup will be retained based on the backups retention setting. |

##### IAM Users

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `connector_enforcement` | `bool` | `false` | Enforce that clients use the connector library |
| `iam_users` | `list(object)` | `[]` | A list of IAM users to be created in your CloudSQL instance. iam.users.type can be `CLOUD_IAM_USER`, `CLOUD_IAM_SERVICE_ACCOUNT`, `CLOUD_IAM_GROUP` and is required for type `CLOUD_IAM_GROUP` (IAM groups) |

## Networking

### Private Service Access (PSA)

The module automatically creates:
- A dedicated VPC network: `cloudsql-{environment}-psa`
- Private Service Access connection with address `10.220.0.0/16`

### IP Configuration (Hardcoded)

The following network settings are hardcoded in the module:

```hcl
ip_configuration = {
  ssl_mode                      = "ENCRYPTED_ONLY"     # Force SSL/TLS
  authorized_networks           = var.cloudsql.allowed_ip_ranges
  ipv4_enabled                  = true                 # Public IP (can be removed if only private)
  private_network               = google_compute_network.psa.id
  psc_enabled                   = true                 # Private Service Connect
  psc_allowed_consumer_projects = [platform_project_id]
}
```

## User Management

### Default User

The module creates a default `postgres` user with a randomly generated password (16 characters with special characters). The password is available as an output.

## Outputs

| Output | Description |
|--------|-------------|
| `initial_password` | The randomly generated password for the default `postgres` user (sensitive) |