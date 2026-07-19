output "permission_set_arns" {
  value = { for name, permission_set in aws_ssoadmin_permission_set.this : name => permission_set.arn }
}

output "enabled" {
  value = local.enabled
}
