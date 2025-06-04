output "initial_password" {
  description = "The initial password for AlloyDB"
  value       = random_password.alloydb_initial_password.result
  sensitive   = true
}