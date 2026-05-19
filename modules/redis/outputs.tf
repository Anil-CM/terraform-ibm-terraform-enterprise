output "redis_password_base64" {
  description = "Base64 encoded Redis password"
  value       = data.kubernetes_secret_v1.redis_password.data["redis-password"]
  sensitive   = true
}

output "redis_password" {
  description = "Decoded Redis password"
  value       = base64decode(data.kubernetes_secret_v1.redis_password.data["redis-password"])
  sensitive   = true
}

output "redis_host" {
  description = "The Redis host for TFE"
  value       = "${local.release_name}-master.${local.namespace}.svc.cluster.local"
}

output "redis_port" {
  description = "The Redis port"
  value       = "6379"
}

output "redis_connection_string" {
  description = "Redis connection string for TFE (without password)"
  value       = "${local.release_name}-master.${local.namespace}.svc.cluster.local:6379"
}

output "namespace" {
  description = "Kubernetes namespace where Redis is deployed"
  value       = local.namespace
}

output "release_name" {
  description = "Helm release name for Redis"
  value       = local.release_name
}
