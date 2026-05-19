locals {
  namespace    = var.namespace != null ? var.namespace : "redis-tfe"
  release_name = var.release_name != null ? var.release_name : "redis"
}

resource "helm_release" "redis_install" {
  name             = local.release_name
  repository       = "oci://registry-1.docker.io/bitnamicharts"
  chart            = "redis"
  version          = var.chart_version
  namespace        = local.namespace
  create_namespace = true
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true
  reset_values     = true
  atomic           = true

  # Redis 7.x configuration
  set {
    name  = "image.tag"
    value = var.redis_version
  }

  # Authentication
  set {
    name  = "auth.enabled"
    value = "true"
  }

  set_sensitive {
    name  = "auth.password"
    value = var.redis_password != null ? var.redis_password : random_password.redis_password[0].result
  }

  # Persistence
  set {
    name  = "master.persistence.enabled"
    value = var.persistence_enabled
  }

  set {
    name  = "master.persistence.size"
    value = var.persistence_size
  }

  set {
    name  = "master.persistence.storageClass"
    value = var.storage_class
  }

  # Resources
  set {
    name  = "master.resources.requests.memory"
    value = var.master_memory_request
  }

  set {
    name  = "master.resources.requests.cpu"
    value = var.master_cpu_request
  }

  set {
    name  = "master.resources.limits.memory"
    value = var.master_memory_limit
  }

  set {
    name  = "master.resources.limits.cpu"
    value = var.master_cpu_limit
  }

  # High Availability (optional)
  set {
    name  = "replica.replicaCount"
    value = var.replica_count
  }

  set {
    name  = "replica.persistence.enabled"
    value = var.persistence_enabled
  }

  set {
    name  = "replica.persistence.size"
    value = var.persistence_size
  }

  # Metrics (optional)
  set {
    name  = "metrics.enabled"
    value = var.metrics_enabled
  }

  # Security Context for OpenShift
  set {
    name  = "master.podSecurityContext.enabled"
    value = "true"
  }

  set {
    name  = "master.podSecurityContext.fsGroup"
    value = "1001"
  }

  set {
    name  = "master.containerSecurityContext.enabled"
    value = "true"
  }

  set {
    name  = "master.containerSecurityContext.runAsUser"
    value = "1001"
  }

  set {
    name  = "master.containerSecurityContext.runAsNonRoot"
    value = "true"
  }
}

# Generate random password if not provided
resource "random_password" "redis_password" {
  count   = var.redis_password == null ? 1 : 0
  length  = 32
  special = true
}

data "kubernetes_secret_v1" "redis_password" {
  depends_on = [helm_release.redis_install]
  metadata {
    name      = local.release_name
    namespace = local.namespace
  }
}
