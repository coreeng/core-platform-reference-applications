# CloudSQL PostgreSQL Module

This module creates Google Cloud SQL PostgreSQL instances with comprehensive configuration options.

It wraps the official [terraform-google-sql-db PostgreSQL module](https://github.com/terraform-google-modules/terraform-google-sql-db/tree/main/modules/postgresql) with opinionated defaults and additional functionality.

## Module Features

- **Private Service Access (PSA)**: Automatic VPC network and PSA setup for private connectivity
- **Private Service Connect (PSC)**: Enabled for secure cross-project database access
- **High Availability**: Support for regional (HA) or zonal deployments
- **Comprehensive Backup**: Point-in-time recovery (PITR) with configurable retention
- **Security First**: Encrypted connections only, deletion protection by default, password validation policies
- **Audit Logging**: pgAudit extension enabled by default for comprehensive activity monitoring
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
| `databases` | `list(object)` | (required) | A list of databases to be created. Each object has:<br>• `name` - Database name<br>• `charset` - Character set (optional, default: `""`)<br>• `collation` - Collation (optional, default: `""`)<br>• `iam_users` - List of IAM users with comprehensive privileges on this specific database (optional, default: `[]`). Each IAM user object has:<br>&nbsp;&nbsp;◦ `id` - User identifier<br>&nbsp;&nbsp;◦ `email` - User email/service account<br>&nbsp;&nbsp;◦ `type` - User type (optional, required for `CLOUD_IAM_GROUP`)<br>&nbsp;&nbsp;◦ `roles` - List of PostgreSQL roles to grant to this user (optional, default: `[]`) |

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

If near zero downtime planned maintenance is required please consult Google's [documentation](https://docs.cloud.google.com/sql/docs/postgres/maintenance#nearzero) for prerequisites and constraints.

##### Backup Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `backup_configuration.enabled` | `bool` | `true` | Enable automated backups |
| `backup_configuration.start_time` | `string` | `"01:00"` | Backup start time in HH:MM format (UTC) |
| `backup_configuration.location` | `string` | `null` | Multi-region location for backups (e.g., `us`, `eu`). Default: same as instance region |
| `backup_configuration.point_in_time_recovery_enabled` | `bool` | `true` | Enable continuous backup for point-in-time recovery |
| `backup_configuration.transaction_log_retention_days` | `string` | `"7"` | Number of days to retain transaction logs for PITR (1-7 for PITR, up to 14 for Enterprise Plus) |
| `backup_configuration.retained_backups` | `number` | `21` | Number of backups to retain |
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
| `connector_enforcement` | `bool` | `true` | Enforce that clients use the connector library |
| `public_ip_enabled` | `bool` | `true` | Enable public IPv4 address for the instance. When `false`, the instance is only accessible via private IP through VPC/PSA, which requires network connectivity to the private network (e.g., VPN, or running from within GCP). The `cloud-sql-proxy` command must include the `--private-ip` flag when public IP is disabled. |
| `deletion_protection` | `bool` | `true` | Enables protection of an Cloud SQL instance from accidental deletion across all surfaces (API, gcloud, Cloud Console and Terraform) |
| `database_deletion_policy` | `string` | `"ABANDON"` | The deletion policy for the database, `ABANDON` is useful for PostgreSQL where databases cannot be deleted from the API if there are users other than cloudsqlsuperuser with access |
| `retain_backups_on_delete` | `bool` | `false` | When this parameter is set to true, Cloud SQL retains backups of the instance even after the instance is deleted. The ON_DEMAND backup will be retained until customer deletes the backup or the project. The AUTOMATED backup will be retained based on the backups retention setting. |

##### Password Validation Policy

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `password_validation_policy_config.min_length` | `number` | `8` | Minimum password length |
| `password_validation_policy_config.complexity` | `string` | `"COMPLEXITY_DEFAULT"` | Password complexity requirements. Options:<br>• `COMPLEXITY_DEFAULT` - Requires a mix of uppercase, lowercase, numbers, and special characters<br>• `COMPLEXITY_UNSPECIFIED` - No complexity requirements |
| `password_validation_policy_config.reuse_interval` | `number` | `0` | Number of previous passwords that cannot be reused (0 = no restriction) |
| `password_validation_policy_config.disallow_username_substring` | `bool` | `true` | Prevents passwords from containing the username as a substring |
| `password_validation_policy_config.password_change_interval` | `string` | (none) | Minimum time interval before a password can be changed (e.g., `"30d"` for 30 days) |

##### Audit Configuration

The module automatically configures audit logging using [pgAudit](https://www.pgaudit.org/) for comprehensive database activity monitoring.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `audit_config.enabled` | `bool` | `true` | Enable pgAudit extension for audit logging |
| `audit_config.log_statement_classes` | `string` | `"all"` | Classes of statements to log. Options:<br>• `"all"` - Log all statement classes (comprehensive logging)<br>• `"read"` - Log SELECT and COPY when the source is a relation<br>• `"write"` - Log INSERT, UPDATE, DELETE, TRUNCATE, and COPY when the destination is a relation<br>• `"ddl"` - Log all DDL that is not included in the ROLE class<br>• `"role"` - Log statements related to roles and privileges (CREATE/DROP/ALTER ROLE, GRANT, REVOKE)<br>• `"function"` - Log function calls and DO blocks<br>• `"misc"` - Log miscellaneous commands (e.g., DISCARD, FETCH, CHECKPOINT, VACUUM, SET)<br>• Multiple classes can be combined with commas (e.g., `"read,write,ddl"`) |

## Networking

### Private Service Access (PSA)

The module automatically creates:
- A dedicated VPC network: `cloudsql-{environment}-psa`
- Private Service Access connection with address `10.220.0.0/16`

### IP Configuration

The module configures the following network settings:

```hcl
ip_configuration = {
  ssl_mode                      = "ENCRYPTED_ONLY"     # Force SSL/TLS (hardcoded)
  authorized_networks           = var.cloudsql.allowed_ip_ranges
  ipv4_enabled                  = each.value.public_ip_enabled  # Configurable, defaults to false
  private_network               = google_compute_network.psa.id # PSA network (hardcoded)
  psc_enabled                   = true                 # Private Service Connect (hardcoded)
  psc_allowed_consumer_projects = [platform_project_id]  # (hardcoded)
}
```

**Notes**:
- With `public_ip_enabled = true` (default), the instance has both public and private IPs. Connector enforcement still ensures secure connections.
- With `public_ip_enabled = false`, the instance only has a private IP, providing maximum security but requiring:
  - Network connectivity to the private IP range (10.220.0.0/16) via VPN, Cloud VPN, or running from within GCP
  - The `--private-ip` flag when using `cloud-sql-proxy` command
  - Terraform provisioner must run from a location with private network access

## User Management

### Default User

The module creates a default `postgres` user with a randomly generated password (16 characters with special characters). The password is available as an output.

### IAM User Permissions

IAM users are configured **per database** in the `databases[].iam_users` list. This allows fine-grained access control where different databases can have different users.

When IAM users are configured for any database:

1. **IAM Authentication** is automatically enabled via the `cloudsql.iam_authentication` database flag
2. **IAM roles** are automatically granted to each IAM service account on the infrastructure project:
   - `roles/cloudsql.client` - Allows calling the Cloud SQL Admin API for connection metadata
   - `roles/cloudsql.instanceUser` - Allows authenticating to Cloud SQL instances using IAM
   - `roles/serviceusage.serviceUsageConsumer` - Allows cross-project access (platform → infrastructure)
3. **Comprehensive PostgreSQL privileges** are automatically granted to each IAM user for **only the databases they are specified in**
4. The privilege grants are performed using `cloud-sql-proxy` and `psql` during `terraform apply` via a `null_resource` provisioner

**Privileges Granted** (per database):
- `ALL PRIVILEGES` on the database (includes CONNECT, CREATE, TEMPORARY)
- `ALL PRIVILEGES` on the `public` schema
- `ALL PRIVILEGES` on all existing tables, sequences, and functions in `public` schema
- `ALTER DEFAULT PRIVILEGES` for future tables, sequences, and functions in `public` schema

**PostgreSQL Role Grants**:
- Optionally, additional PostgreSQL roles can be granted to IAM users by specifying the `roles` list in the IAM user configuration
- Common built-in roles include: `pg_read_all_data`, `pg_write_all_data`, `pg_read_all_settings`, `pg_read_all_stats`, `pg_monitor`, `pg_signal_backend`
- Roles are granted using `GRANT "<role>" TO "<iam_user>";` during the provisioning process
- If a role doesn't exist or is already granted, the process continues with a warning

**Note**: PostgreSQL truncates IAM usernames to end at `.iam` due to the 63-character username limit. For example, `service-account@project.iam.gserviceaccount.com` becomes `service-account@project.iam` in the database.

## Outputs

| Output | Description |
|--------|-------------|
| `initial_password` | The randomly generated password for the default `postgres` user (sensitive) |
