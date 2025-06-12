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
  timeout_sec           = 600

  backend {
    group = google_compute_global_network_endpoint_group.neg[each.key].id
  }

  custom_request_headers = [
    "Host: ${each.value.host}"
  ]
}

# A Backend Service wth no backend to use as a default service
resource "google_compute_backend_service" "bs_default" {
  name                  = "${local.name_prefix}-default-error"
  project               = var.infrastructure_project_id
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  # no `backend {}` blocks here → any call into this service returns 503
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
    for_each = local.routes_map
    content {
      hosts        = [host_rule.value.host]
      path_matcher = host_rule.key
    }
  }

  # path matchers with weighted backends
  dynamic "path_matcher" {
    for_each = local.routes_map
    content {
      name = path_matcher.key

      default_route_action {
        # for each endpoint belonging to this route, pull in its backend service + weight
        dynamic "weighted_backend_services" {
          for_each = [
            for ep in local.endpoints_flat : ep
            if ep.route == path_matcher.key
          ]
          content {
            backend_service = google_compute_backend_service.bs["${weighted_backend_services.value.route}-${weighted_backend_services.value.name}"].self_link
            weight          = weighted_backend_services.value.weight
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