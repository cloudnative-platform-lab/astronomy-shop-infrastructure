data "aws_caller_identity" "current" {}

locals {
  enabled    = var.enable_identity_center && var.sso_instance_arn != null && var.identity_store_id != null
  account_id = var.account_id != null ? var.account_id : data.aws_caller_identity.current.account_id
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each = local.enabled ? var.permission_sets : {}

  name             = each.key
  description      = each.value.description
  instance_arn     = var.sso_instance_arn
  session_duration = each.value.session_duration
  tags             = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = local.enabled ? {
    for attachment in flatten([
      for permission_set_name, permission_set in var.permission_sets : [
        for policy_arn in permission_set.managed_policies : {
          key                 = "${permission_set_name}:${policy_arn}"
          permission_set_name = permission_set_name
          policy_arn          = policy_arn
        }
      ]
    ]) : attachment.key => attachment
  } : {}

  instance_arn       = var.sso_instance_arn
  managed_policy_arn = each.value.policy_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set_name].arn
}

resource "aws_ssoadmin_account_assignment" "group" {
  for_each = local.enabled ? var.group_assignments : {}

  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set_name].arn
  principal_id       = each.value.group_id
  principal_type     = "GROUP"
  target_id          = local.account_id
  target_type        = "AWS_ACCOUNT"
}
