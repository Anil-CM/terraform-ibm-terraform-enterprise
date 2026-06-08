########################################################################################################################
# Outputs
########################################################################################################################

output "resource_group_id" {
  value       = var.resource_group_id
  description = "The ID of the provisioned resource group."
}

output "cos_instance_id" {
  value       = module.cos.cos_instance_id
  description = "The name of the provisioned cos instance."
}

output "vpc_id" {
  value       = module.ocp_vpc.vpc_id
  description = "The ID of the VPC."
}

output "vpc_subnets" {
  description = "The subnets of the VPC, including the ID, the subnet zone and the subnet CIDR."
  value = { for subnet in module.ocp_vpc.vpc_subnet_zone_list :
    subnet.name => {
      id   = subnet.id
      zone = subnet.zone
      cidr = subnet.cidr
    }
  }
}

output "cluster_id" {
  value       = module.ocp_vpc.cluster_id
  description = "The ID of the provisioned cluster. Null if no cluster is created or provided."
}

output "icd_postgres_hostname" {
  description = "The hostname of the provisioned Postgres instance."
  value       = module.icd_postgres.hostname
}

output "icd_postgres_port" {
  description = "The port of the provisioned Postgres instance listens on."
  value       = module.icd_postgres.port
}

output "icd_postgres_crn" {
  value       = module.icd_postgres.crn
  description = "The crm of the provisioned Postgres instance."
}

output "icd_postgres_vpe" {
  value       = module.icd_postgres_vpe
  description = "Details of the Virtual Private Endpoint created towards postgres instance"
}

output "icd_redis_hostname" {
  description = "The hostname of the provisioned Redis instance."
  value       = module.icd_redis.hostname
}

output "icd_redis_port" {
  description = "The port of the provisioned Redis instance listens on."
  value       = module.icd_redis.port
}

output "icd_redis_crn" {
  value       = module.icd_redis.crn
  description = "The CRN of the provisioned Redis instance."
}

output "icd_redis_vpe" {
  value       = module.icd_redis_vpe
  description = "Details of the Virtual Private Endpoint created towards Redis instance"
}

output "redis_host" {
  value       = local.redis_host
  description = "The hostname of the provisioned redis host."
}

output "redis_port" {
  value       = local.redis_port
  description = "The port of the provisioned redis instance."
}

output "redis_password" {
  value       = var.existing_secrets_manager_crn == null ? local.redis_pass_base64 : null
  description = "password to redis instance, this is set to null when a value for `existing_secrets_manager_crn` is provided"
  sensitive   = true
}

output "tfe_console_url" {
  value       = length(module.tfe_install) > 0 ? module.tfe_install[0].tfe_console_url : null
  description = "url to access Terraform Enterprise. Null if TFE is not installed."
}

output "tfe_hostname" {
  value       = length(module.tfe_install) > 0 ? module.tfe_install[0].tfe_hostname : null
  description = "The hostname for Terraform Enterprise instance. Null if TFE is not installed."
}

output "redis_password_secret_crn" {
  value       = var.existing_secrets_manager_crn != null ? module.redis_password_secret[0].secret_crn : null
  description = "The CRN of the secret containing the redis admin password"
}

output "final_acl_rules" {
  description = "The final set of ACL rules applied to the VPC, including any rules added for Postgres connectivity."
  value       = local.final_acl_rules
}

output "kube_cluster_sg" {
  description = "The ID of the default security group representing the cluster nodes. Null if no cluster is created or provided."
  value       = module.ocp_vpc.kube_cluster_sg != null ? module.ocp_vpc.kube_cluster_sg.id : null
}

output "vpc_default_security_group" {
  description = "The ID of the VPC default security group."
  value       = module.ocp_vpc.vpc_default_security_group
}

output "vpc_kubecluster_sg_rule" {
  description = "The Security group rule going to be attached to the cluster default Security Group in order to enable Postgres connectivity."
  value       = ibm_is_security_group_rule.vpc_kubecluster_sg_rule
}

output "vpc_kubecluster_redis_sg_rule" {
  description = "The Security group rule going to be attached to the cluster default Security Group in order to enable Redis connectivity."
  value       = ibm_is_security_group_rule.vpc_kubecluster_redis_sg_rule
}

output "tfe_secondary_hostname_fqdn" {
  description = "The FQDN for the Terraform Enterprise secondary hostname. Null if no secondary hostname is created or TFE is not installed."
  value       = length(module.tfe_install) > 0 && var.tfe_secondary_host != null ? "https://${local.tfe_secondary_hostname_fqdn}" : null
}
