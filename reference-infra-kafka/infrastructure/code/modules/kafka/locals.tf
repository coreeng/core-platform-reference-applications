locals {
  clusters = {
    for cluster in var.kafka.clusters : cluster.name => merge(cluster, {
      cluster_id = "${cluster.name}-${var.environment}-cluster"
    })
  }

  connected_subnets = flatten([
    for cluster_name, cluster in local.clusters : [
      for subnet in cluster.connected_subnets : merge(subnet, {
        cluster_name = cluster_name
        project_id   = coalesce(try(subnet.project_id, null), var.platform_project_id)
      })
    ]
  ])

  service_agent_project_grants = toset([
    for subnet in local.connected_subnets : subnet.project_id
    if subnet.grant_service_agent_role
  ])

  client_principals = toset(distinct(flatten([
    for cluster in local.clusters : cluster.client_principals
  ])))

  topics = merge({}, [
    for cluster_name, cluster in local.clusters : {
      for topic in cluster.topics : "${cluster_name}/${topic.name}" => merge(topic, {
        cluster_name = cluster_name
        cluster_id   = cluster.cluster_id
      })
    }
  ]...)

  acls = merge({}, [
    for cluster_name, cluster in local.clusters : {
      for acl in cluster.acls : "${cluster_name}/${acl.id}" => merge(acl, {
        cluster_name = cluster_name
        cluster_id   = cluster.cluster_id
      })
    }
  ]...)
}
