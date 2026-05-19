output "initial_password" {
  description = "The initial password for Cloud SQL"
  value       = random_password.cloudsql_initial_password.result
  sensitive   = true
}
