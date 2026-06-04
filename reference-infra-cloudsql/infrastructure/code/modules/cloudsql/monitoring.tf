resource "google_project_service" "monitoring" {
  project                    = var.infrastructure_project_id
  service                    = "monitoring.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_monitoring_notification_channel" "cloudsql_email" {
  for_each = toset(var.cloudsql.monitoring.notification_emails)

  project      = var.infrastructure_project_id
  display_name = "Cloud SQL alerts - ${each.value}"
  type         = "email"

  labels = {
    email_address = each.value
  }

  depends_on = [google_project_service.monitoring]
}

resource "google_monitoring_alert_policy" "cloudsql_metric" {
  for_each = local.cloudsql_alert_policies

  project               = var.infrastructure_project_id
  display_name          = "Cloud SQL ${each.value.display_name} - ${each.value.instance_name}"
  combiner              = "OR"
  enabled               = true
  notification_channels = local.cloudsql_notification_channels

  conditions {
    display_name = "Cloud SQL ${each.value.display_name} above threshold"

    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${var.infrastructure_project_id}:${each.value.instance_name}\" AND metric.type = \"${each.value.metric_type}\""
      comparison      = "COMPARISON_GT"
      duration        = "300s"
      threshold_value = each.value.threshold

      aggregations {
        alignment_period   = each.value.alignment_period
        per_series_aligner = each.value.per_series_aligner
      }

      trigger {
        count = 1
      }
    }
  }

  depends_on = [google_project_service.monitoring]
}
