########################################################################################################################
# Terraform providers
########################################################################################################################


provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  visibility       = "public"
}

# Download cluster config which is required to connect to cluster
# NOTE: This wrapper intentionally does not configure kubernetes/helm/kubectl providers
# from module outputs because doing so creates a dependency cycle during plan when the
# cluster is created in the same graph. Those providers are configured inside the root
# module after the cluster dependency chain is resolved.
#
# For two-pass apply workflow:
# Pass 1: terraform apply (creates infrastructure including cluster)
# Pass 2: terraform apply (installs TFE using the cluster created in pass 1)
