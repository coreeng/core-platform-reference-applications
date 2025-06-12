locals {
  # name prefix
  name_prefix = "urlrouter"

  # map routes by name for easy for_each
  routes_map = { for r in var.urlrouter.routes : r.name => r }

  # flatten endpoints, tagging each with its parent route
  endpoints_flat = flatten([
    for r in var.urlrouter.routes : [
      for ep in r.endpoints : merge(ep, { route = r.name })
    ]
  ])

  # index endpoints so we can lookup the right NEG by key
  endpoints_map = {
    for ep in local.endpoints_flat :
    "${ep.route}-${ep.name}" => ep
  }
}