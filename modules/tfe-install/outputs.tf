##############################################################################
# Outputs
##############################################################################
output "tfe_installation_status" {
  description = "The status of the Terraform Enterprise installation"
  value       = helm_release.tfe_install.status
}

output "tfe_health_status" {
  description = "Health check result for TFE endpoints (readiness, API ping, authenticated API). Value is 'healthy' when all checks pass."
  value       = data.external.tfe_health_check.result["status"]
}

output "tfe_console_url" {
  description = "The URL to access the Terraform Enterprise console"
  value       = "https://${data.kubernetes_resource.tfe_route.object.status.ingress[0].host}"
}

output "tfe_hostname" {
  description = "The hostname for Terraform Enterprise instance"
  value       = data.kubernetes_resource.tfe_route.object.status.ingress[0].host
}

output "token" {
  description = "A Terraform Enterprise user API token for `var.admin_username` account"
  value       = resource.kubernetes_secret_v1.tfe_admin_token.data["token"]
  sensitive   = true
}
