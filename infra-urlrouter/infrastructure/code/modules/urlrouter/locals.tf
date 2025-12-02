locals {
  # name prefix
  name_prefix = "urlrouter"

  routes = var.urlrouter.routes != null ? var.urlrouter.routes : []

  # map routes by name for easy for_each
  routes_map = { for r in local.routes : r.name => r }

  bucket_routes = [
    for r in local.routes :
    r if r.type == "bucket"
  ]

  bucket_routes_map = { for r in local.bucket_routes : r.name => r }

  service_routes = [
    for r in local.routes :
    r if r.type == "service"
  ]

  # flatten endpoints, tagging each with its parent route
  endpoints_flat = flatten([
    for r in local.service_routes : [
      for ep in(r.endpoints != null ? r.endpoints : []) : merge(
        ep,
        {
          route      = r.name
          enable_cdn = lookup(r, "enable_cdn", false)
        }
      )
    ]
  ])

  # index endpoints so we can lookup the right NEG by key
  endpoints_map = {
    for ep in local.endpoints_flat :
    "${ep.route}-${ep.name}" => ep
  }

  # group endpoints by route and path for path-based routing
  endpoints_by_route_and_path = {
    for r in local.service_routes : r.name => {
      for path in distinct([
        for ep in(r.endpoints != null ? r.endpoints : []) :
        lookup(ep, "path", "/")
        ]) : path => [
        for ep in(r.endpoints != null ? r.endpoints : []) :
        ep if lookup(ep, "path", "/") == path
      ]
    }
  }
}
