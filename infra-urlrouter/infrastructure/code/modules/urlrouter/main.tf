# Metadata about the infrastructure project
data "google_project" "infrastructure" {
  project_id = var.infrastructure_project_id
}

# A Global IP for the Global Load Balancer
resource "google_compute_global_address" "lb_ip" {
  name    = "${local.name_prefix}-ip"
  project = var.infrastructure_project_id
}

# A DNS authorization per route
resource "google_certificate_manager_dns_authorization" "dns_auth" {
  for_each = local.routes_map
  name     = "${local.name_prefix}-${each.key}"
  project  = var.infrastructure_project_id
  domain   = each.value.host
}

# A certificate map
resource "google_certificate_manager_certificate_map" "map" {
  name    = local.name_prefix
  project = var.infrastructure_project_id
}

# A managed cert per route
resource "google_certificate_manager_certificate" "cert" {
  for_each = local.routes_map
  name     = "${local.name_prefix}-${each.key}"
  project  = var.infrastructure_project_id

  managed {
    domains = [each.value.host]
    dns_authorizations = [
      google_certificate_manager_dns_authorization.dns_auth[each.key].id
    ]
  }
}

# A certificate map entry per cert
resource "google_certificate_manager_certificate_map_entry" "entry" {
  for_each = local.routes_map
  name     = "${local.name_prefix}-${each.key}"
  project  = var.infrastructure_project_id
  map      = google_certificate_manager_certificate_map.map.name
  hostname = each.value.host
  certificates = [
    google_certificate_manager_certificate.cert[each.key].id
  ]
}

# A Global Internet NEG and NE per endpoint
resource "google_compute_global_network_endpoint_group" "neg" {
  for_each              = local.endpoints_map
  name                  = "${local.name_prefix}-${each.key}"
  project               = var.infrastructure_project_id
  network_endpoint_type = "INTERNET_FQDN_PORT"
  default_port          = each.value.port
}

resource "google_compute_global_network_endpoint" "ep" {
  for_each                      = local.endpoints_map
  project                       = var.infrastructure_project_id
  global_network_endpoint_group = google_compute_global_network_endpoint_group.neg[each.key].id
  fqdn                          = each.value.host
  port                          = each.value.port
}

# A Backend Service per endpoint
resource "google_compute_backend_service" "bs" {
  for_each              = local.endpoints_map
  name                  = "${local.name_prefix}-${each.key}"
  project               = var.infrastructure_project_id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP2"
  enable_cdn            = each.value.enable_cdn
  timeout_sec           = 600

  backend {
    group = google_compute_global_network_endpoint_group.neg[each.key].id
  }

  custom_request_headers = [
    "Host: ${each.value.host}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# A Backend Service wth no backend to use as a default service
resource "google_compute_backend_service" "bs_default" {
  name                  = "${local.name_prefix}-default-error"
  project               = var.infrastructure_project_id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  # no `backend {}` blocks here → any call into this service returns 503
}

# A GCS bucket per bucket-backed route
resource "google_storage_bucket" "asset_store" {
  for_each = local.bucket_routes_map

  name                        = each.value.bucket.name
  project                     = var.infrastructure_project_id
  location                    = each.value.bucket.location != null ? each.value.bucket.location : var.region
  labels                      = length(each.value.bucket.labels) > 0 ? each.value.bucket.labels : null
  uniform_bucket_level_access = true
  force_destroy               = false
}

# Allow public read access for bucket-backed routes
resource "google_storage_bucket_iam_member" "asset_store_lb_access" {
  for_each = local.bucket_routes_map

  bucket = google_storage_bucket.asset_store[each.key].name
  role   = "roles/storage.legacyObjectReader"
  member = "allUsers"
}

# Backend bucket per bucket-backed route
resource "google_compute_backend_bucket" "asset_store" {
  for_each = local.bucket_routes_map

  name        = "${local.name_prefix}-${each.key}"
  project     = var.infrastructure_project_id
  bucket_name = google_storage_bucket.asset_store[each.key].name
  enable_cdn  = each.value.bucket.enable_cdn
}

# HTTPS Redirect url map
resource "google_compute_url_map" "https_redirect" {
  name    = "${local.name_prefix}-https-redirect"
  project = var.infrastructure_project_id
  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

# HTTPS URL Routing url map
resource "google_compute_url_map" "https_map" {
  name    = "${local.name_prefix}-https-map"
  project = var.infrastructure_project_id

  default_service = google_compute_backend_service.bs_default.self_link

  # Explicit dependencies to ensure proper ordering during creation and deletion
  depends_on = [
    google_compute_backend_service.bs,
    google_compute_backend_bucket.asset_store
  ]

  # unmatched requests default to 421 - Misdirected Request
  default_route_action {
    fault_injection_policy {
      abort {
        http_status = 421
        percentage  = 100.0
      }
    }
  }

  # host rules
  dynamic "host_rule" {
    for_each = { for k in sort(keys(local.routes_map)) : k => local.routes_map[k] }
    content {
      hosts        = [host_rule.value.host]
      path_matcher = host_rule.key
    }
  }

  # path matchers per host (service and bucket routes)
  dynamic "path_matcher" {
    for_each = { for k in sort(keys(local.routes_map)) : k => local.routes_map[k] }
    content {
      name = path_matcher.key

      default_service = contains(keys(local.bucket_routes_map), path_matcher.key) ? google_compute_backend_bucket.asset_store[path_matcher.key].self_link : null

      # for each endpoint belonging to this route, pull in its backend service + weight (service-backed routes only)
      dynamic "default_route_action" {
        for_each = contains(keys(local.bucket_routes_map), path_matcher.key) ? [] : (
          contains(keys(lookup(local.endpoints_by_route_and_path, path_matcher.key, {})), "/") ? [path_matcher.key] : []
        )
        content {
          dynamic "weighted_backend_services" {
            for_each = [
              for ep in lookup(lookup(local.endpoints_by_route_and_path, path_matcher.key, {}), "/", []) : ep
            ]
            content {
              backend_service = google_compute_backend_service.bs["${path_matcher.key}-${weighted_backend_services.value.name}"].self_link
              weight          = weighted_backend_services.value.weight
            }
          }
        }
      }

      # path rules for non-default paths
      dynamic "path_rule" {
        for_each = contains(keys(local.bucket_routes_map), path_matcher.key) ? {} : {
          for path, endpoints in lookup(local.endpoints_by_route_and_path, path_matcher.key, {}) :
          path => endpoints if path != "/"
        }
        content {
          paths = ["${path_rule.key}", "${path_rule.key}/", "${path_rule.key}/*"]
          route_action {
            dynamic "weighted_backend_services" {
              for_each = path_rule.value
              content {
                backend_service = google_compute_backend_service.bs["${path_matcher.key}-${weighted_backend_services.value.name}"].self_link
                weight          = weighted_backend_services.value.weight
              }
            }

            # URL rewrite if any endpoint specifies path_prefix_rewrite
            dynamic "url_rewrite" {
              for_each = length([for ep in path_rule.value : ep if lookup(ep, "path_prefix_rewrite", null) != null]) > 0 ? [1] : []
              content {
                path_prefix_rewrite = lookup(path_rule.value[0], "path_prefix_rewrite", null)
              }
            }
          }
        }
      }
    }
  }
}

# HTTPS Proxy & Forwarding Rule
resource "google_compute_target_https_proxy" "https" {
  name            = "${local.name_prefix}-https-proxy"
  project         = var.infrastructure_project_id
  url_map         = google_compute_url_map.https_map.self_link
  certificate_map = format("//certificatemanager.googleapis.com/%s", google_certificate_manager_certificate_map.map.id)
}

resource "google_compute_global_forwarding_rule" "https_fr" {
  name                  = "${local.name_prefix}-https"
  project               = var.infrastructure_project_id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "443"
  target                = google_compute_target_https_proxy.https.self_link
}

resource "google_compute_target_http_proxy" "http" {
  name    = "${local.name_prefix}-http-proxy"
  project = var.infrastructure_project_id
  url_map = google_compute_url_map.https_redirect.self_link
}

resource "google_compute_global_forwarding_rule" "http_fr" {
  name                  = "${local.name_prefix}-http"
  project               = var.infrastructure_project_id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "80"
  target                = google_compute_target_http_proxy.http.self_link
}
