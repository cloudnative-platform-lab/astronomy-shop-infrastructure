output "controller_role_arn" { value = try(module.karpenter[0].iam_role_arn, null) }
output "node_role_name" { value = try(module.karpenter[0].node_iam_role_name, null) }

output "allowed_instance_types" { value = var.allowed_instance_types }
output "controller_release_name" { value = try(helm_release.controller[0].name, null) }
output "nodepool_name" { value = var.enabled ? "default" : null }
output "ec2_node_class_name" { value = var.enabled ? "default" : null }
