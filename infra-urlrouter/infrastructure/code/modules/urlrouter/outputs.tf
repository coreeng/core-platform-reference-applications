output "ip_address" {
  description = "The IP address of the URL router"
  value       = google_compute_global_address.lb_ip.address
}

output "dns_authorization_records" {
  description = "The DNS authorization records required to provision managed certificates for the URL router"
  value = {
    for key, auth in google_certificate_manager_dns_authorization.dns_auth :
    key => {
      auth_name = auth.name
      rr_name   = auth.dns_resource_record[0].name
      rr_type   = auth.dns_resource_record[0].type
      rr_data   = auth.dns_resource_record[0].data
    }
  }
}

output "bucket_details" {
  description = "Details about bucket-backed routes"
  value = {
    for key, bucket in google_storage_bucket.asset_store :
    key => {
      name     = bucket.name
      location = bucket.location
    }
  }
}
