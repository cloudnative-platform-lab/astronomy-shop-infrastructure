output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_security_group_id" { value = module.eks.cluster_security_group_id }
output "node_security_group_id" { value = module.eks.node_security_group_id }
output "oidc_provider_arn" { value = module.eks.oidc_provider_arn }

output "cluster_certificate_authority_data" { value = module.eks.cluster_certificate_authority_data }
output "ebs_csi_role_arn" { value = try(aws_iam_role.ebs_csi[0].arn, null) }
output "cloudwatch_observability_role_arn" { value = try(aws_iam_role.cloudwatch_observability[0].arn, null) }
output "container_insights_application_log_group_name" { value = try(aws_cloudwatch_log_group.container_insights_application[0].name, null) }
