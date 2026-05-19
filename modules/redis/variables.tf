##############################################################################
# Redis Module Variables
##############################################################################

variable "namespace" {
  description = "Kubernetes namespace for Redis deployment"
  type        = string
  default     = null
}

variable "release_name" {
  description = "Helm release name for Redis"
  type        = string
  default     = null
}

variable "chart_version" {
  description = "Bitnami Redis Helm chart version"
  type        = string
  default     = "19.0.2" # Latest stable version with Redis 7.x support
}

variable "redis_version" {
  description = "Redis image tag/version"
  type        = string
  default     = "7.2.4-debian-12-r9" # Redis 7.2.4 - compatible with TFE
}

variable "redis_password" {
  description = "Redis password. If not provided, a random password will be generated"
  type        = string
  default     = null
  sensitive   = true
}

variable "persistence_enabled" {
  description = "Enable persistence for Redis data"
  type        = bool
  default     = true
}

variable "persistence_size" {
  description = "Size of the persistent volume for Redis"
  type        = string
  default     = "10Gi"
}

variable "storage_class" {
  description = "Storage class for Redis persistent volumes"
  type        = string
  default     = "" # Uses cluster default storage class
}

variable "master_memory_request" {
  description = "Memory request for Redis master"
  type        = string
  default     = "256Mi"
}

variable "master_cpu_request" {
  description = "CPU request for Redis master"
  type        = string
  default     = "250m"
}

variable "master_memory_limit" {
  description = "Memory limit for Redis master"
  type        = string
  default     = "512Mi"
}

variable "master_cpu_limit" {
  description = "CPU limit for Redis master"
  type        = string
  default     = "500m"
}

variable "replica_count" {
  description = "Number of Redis replicas for high availability"
  type        = number
  default     = 0 # Set to 1 or more for HA setup
}

variable "metrics_enabled" {
  description = "Enable Prometheus metrics for Redis"
  type        = bool
  default     = false
}