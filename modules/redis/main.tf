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

  values = [
    yamlencode({
      image = {
        tag = var.redis_version
      }
      auth = {
        enabled  = true
        password = var.redis_password != null ? var.redis_password : random_password.redis_password[0].result
      }
      master = {
        persistence = {
          enabled      = var.persistence_enabled
          size         = var.persistence_size
          storageClass = var.storage_class
        }
        resources = {
          requests = {
            memory = var.master_memory_request
            cpu    = var.master_cpu_request
          }
          limits = {
            memory = var.master_memory_limit
            cpu    = var.master_cpu_limit
          }
        }
        podSecurityContext = {
          enabled = true
          fsGroup = 1001
        }
        containerSecurityContext = {
          enabled      = true
          runAsUser    = 1001
          runAsNonRoot = true
        }
      }
      replica = {
        replicaCount = var.replica_count
        persistence = {
          enabled = var.persistence_enabled
          size    = var.persistence_size
        }
      }
      metrics = {
        enabled = var.metrics_enabled
      }
    })
  ]
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
