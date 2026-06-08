<!-- Update this title with a descriptive name. Use sentence case. -->
# IBM Cloud Terraform Enterprise modules

[![Supported (stable)](https://img.shields.io/badge/Status-Supported%20(stable)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-terraform-enterprise?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-terraform-enterprise/releases/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-623CE4?logo=terraform)](https://registry.terraform.io/modules/terraform-ibm-modules/terraform-enterprise/ibm/latest)

## Overview

This repository provides a top-level Terraform module for deploying and managing Terraform Enterprise on IBM Cloud Red Hat OpenShift or Kubernetes clusters. The module automates the setup of namespaces, secrets, Helm releases, routes, and supporting resources required for a Terraform Enterprise installation.

**Status:** This module deploys a production-ready Terraform Enterprise infrastructure on IBM Cloud with comprehensive security, scalability, and compliance features.

### Helm Chart Migration

This module now uses the official Terraform Enterprise Helm chart from `https://helm.releases.hashicorp.com` instead of a local chart. The Helm chart version can be controlled via the `helm_chart_version` variable (defaults to `1.6.8`). For migration details, see [HELM_CHART_MIGRATION.md](./HELM_CHART_MIGRATION.md).

### Custom Terraform Enterprise Agent Image

This module automatically builds and deploys a custom Terraform Enterprise agent image that includes additional tools for IBM Cloud operations:

**What is the Custom Agent?**
The custom agent is a container image based on the official HashiCorp `tfc-agent` image, enhanced with IBM Cloud-specific tools. Terraform Enterprise uses these agents to execute Terraform runs in isolated containers.

**Why is it Needed?**
The custom agent provides:
- **kubectl**: Kubernetes command-line tool for managing cluster resources
- **oc**: OpenShift command-line tool for OpenShift-specific operations
- **IBM Cloud CLI** (planned): For managing IBM Cloud resources directly from Terraform runs

**How it Works:**
1. The module creates an OpenShift BuildConfig that builds the custom image
2. The image is stored in the cluster's internal image registry
3. Terraform Enterprise is configured to use this custom image for all Terraform runs via `TFE_RUN_PIPELINE_IMAGE`
4. The image is automatically rebuilt when the base `tfc-agent` image is updated

**Image Location:**
The custom agent image is stored in the OpenShift internal registry and is not exposed externally. It's automatically managed by the module.

### Terraform Enterprise Version Management

The Terraform Enterprise version is specified using the `tfe_image_tag` variable, which corresponds to the Terraform Enterprise release version (e.g., `v202501-1`). You can find available versions in the [Terraform Enterprise Release Notes](https://developer.hashicorp.com/terraform/enterprise/releases).

**Upgrade Strategy:** To upgrade Terraform Enterprise:
1. Update the `tfe_image_tag` variable to the desired version
2. Review the [release notes](https://developer.hashicorp.com/terraform/enterprise/releases) for breaking changes
3. Test the upgrade in a non-production environment first
4. Apply the Terraform configuration to perform a rolling update
5. The Helm chart will perform a rolling update of the Terraform Enterprise pods

### Backup Strategy

**PostgreSQL Backups:** IBM Cloud Databases for PostgreSQL automatically creates daily backups with point-in-time recovery. Backups are encrypted using the KMS key specified in `backup_encryption_key_crn` and retained according to IBM Cloud's backup retention policies.

**Object Storage Backups:** Terraform Enterprise state files and artifacts are stored in IBM Cloud Object Storage (COS), which provides:
- Cross-region replication (when configured)
- Versioning capabilities
- Encryption at rest using KMS

**Redis Data:** Redis is used for caching and session management. Data in Redis is ephemeral and does not require backup as it can be regenerated.

**Disaster Recovery:** To restore Terraform Enterprise:
1. Deploy a new instance using this module with the same configuration
2. Point to the existing PostgreSQL instance and COS bucket
3. Terraform Enterprise will automatically reconnect to existing data

### Terraform Enterprise Secondary hostname

This module supports configuring the Terraform Enterprise instance with a [secondary hostname](https://developer.hashicorp.com/terraform/enterprise/deploy/reference/configuration#tfe_hostname_secondary) by:
- Integrating with an existing IBM Cloud Internet Services instance providing an already configured domain (e.g., `example.com`) for DNS support
- Providing the host to add to the existing domain DNS configuration (e.g., `tfe-host`) and configuring the route for the final secondary Fully Qualified Domain Name (FQDN) on the cluster (e.g., `tfe-host.example.com`)
- Integrating with an existing secret in IBM Secrets Manager instance to pull the TLS certificate to configure for the route that serves the secondary FQDN

## Required access policies

You need the following permissions to run this module:

- IBM Cloud Resource Group: `Viewer` access on the resource group
- IBM Cloud OpenShift or Kubernetes: `Editor` or `Administrator` access to the cluster
- IBM Cloud Object Storage: `Manager` or `Writer` access for the S3 bucket
- IBM Cloud Databases for PostgreSQL: `Manager` or equivalent access
- IBM Cloud Databases for Redis: `Manager` or equivalent access
- IBM Cloud Secrets Manager: `Writer` access if the generated secrets are to be stored in Secrets Manager
- IBM Cloud Secrets Manager: `SecretsReader` access if the Terraform Enterprise license key is in Secrets Manager
- Ability to create and manage Kubernetes resources in the target OpenShift namespace

## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.

## Configuration Variables

This module exposes most Terraform Enterprise configuration variables through the Helm chart values. You can pass additional configuration by using the `tfe_*` variables. For a complete list of available Terraform Enterprise configuration options, see the [Terraform Enterprise Configuration Reference](https://developer.hashicorp.com/terraform/enterprise/deploy/reference/configuration).

Common configuration variables include:
- `TFE_HOSTNAME`: Automatically configured based on the cluster ingress
- `TFE_DATABASE_*`: Database connection settings
- `TFE_OBJECT_STORAGE_*`: Object storage configuration
- `TFE_REDIS_*`: Redis connection settings
- `TFE_CAPACITY_*`: Capacity and scaling settings

## Notes

The module integrates with IBM Cloud Secrets Manager service. This integration takes two forms. If an optional IBM Cloud Secrets Manager instance CRN and secret group ID are provided, then the Redis admin user password and Terraform Enterprise admin token will be stored in Secrets Manager and the new secret CRNs will be returned instead of the secret values. If an optional Terraform Enterprise license secret CRN is provided, then the license will be retrieved from Secrets Manager, avoiding the need to pass the license key as a string.

## Cluster Options

This module supports deployment on both:
- **Red Hat OpenShift on IBM Cloud**: Full-featured enterprise Kubernetes platform with enhanced security and developer tools
- **IBM Cloud Kubernetes Service (IKS)**: Standard Kubernetes clusters for cost-effective deployments

The cluster type is automatically detected based on the provided `cluster_id`. Both platforms support the same Terraform Enterprise features and configurations.

## Known issues

Tear down will fail at the PostgreSQL instance when delete protection is enabled. Set the delete protection flag to false and run `terraform apply --target 'module.<top level module name>.module.icd_postgres.ibm_database.postgresql_db'` before running the destroy to complete the tear down.
