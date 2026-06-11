resource "google_project_service" "cloud_ids" {
  count = local.cloud_ids_enabled ? 1 : 0

  project                    = var.infrastructure_project_id
  service                    = "ids.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "logging" {
  count = local.cloud_ids_enabled && local.cloud_ids_notifications_enabled ? 1 : 0

  project                    = var.infrastructure_project_id
  service                    = "logging.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_cloud_ids_endpoint" "psa" {
  count = local.cloud_ids_enabled ? 1 : 0

  project  = var.infrastructure_project_id
  name     = "cloudsql-${var.environment}-ids"
  location = local.cloud_ids_location
  network  = google_compute_network.psa.id
  severity = local.cloud_ids_severity

  depends_on = [google_project_service.cloud_ids, module.cloudsql-psa]
}

resource "google_compute_packet_mirroring" "psa" {
  count = local.cloud_ids_enabled ? 1 : 0

  project = var.infrastructure_project_id
  region  = var.region
  name    = "cloudsql-${var.environment}-ids-mirroring"

  network {
    url = google_compute_network.psa.id
  }

  collector_ilb {
    url = google_cloud_ids_endpoint.psa[0].endpoint_forwarding_rule
  }

  mirrored_resources {
    tags = local.cloud_ids_packet_mirroring_tags
  }

  filter {
    direction   = "BOTH"
    cidr_ranges = ["0.0.0.0/0"]
  }
}

resource "google_logging_metric" "cloud_ids_threat_detections" {
  count = local.cloud_ids_enabled && local.cloud_ids_notifications_enabled ? 1 : 0

  project = var.infrastructure_project_id
  name    = "cloud_ids_${var.environment}_threat_detections"
  filter  = "resource.type=\"ids.googleapis.com/Endpoint\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }

  depends_on = [google_project_service.logging]
}

resource "google_monitoring_alert_policy" "cloud_ids_threat_detections" {
  count = local.cloud_ids_enabled && local.cloud_ids_notifications_enabled && length(var.cloudsql.monitoring.notification_emails) > 0 ? 1 : 0

  project               = var.infrastructure_project_id
  display_name          = "Cloud IDS threat detections - cloudsql-${var.environment}-psa"
  combiner              = "OR"
  enabled               = true
  notification_channels = local.cloudsql_notification_channels

  conditions {
    display_name = "Cloud IDS endpoint threat detection logs"

    condition_threshold {
      filter          = "resource.type=\"ids.googleapis.com/Endpoint\" AND metric.type=\"logging.googleapis.com/user/${google_logging_metric.cloud_ids_threat_detections[0].name}\""
      comparison      = "COMPARISON_GT"
      duration        = "0s"
      threshold_value = 0

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  depends_on = [
    google_project_service.monitoring,
    google_logging_metric.cloud_ids_threat_detections,
  ]
}
