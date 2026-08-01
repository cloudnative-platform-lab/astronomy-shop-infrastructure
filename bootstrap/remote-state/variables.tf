variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Optional globally unique S3 bucket name for Terraform state. Leave null to generate an account-based name."
  default     = null
}

variable "lock_table_name" {
  type        = string
  description = "DynamoDB table name for Terraform state locking."
  default     = "terraform-locks"
}

variable "force_destroy_state_bucket" {
  type        = bool
  description = "Allow deleting the state bucket even when objects exist. Keep false for real environments."
  default     = false
}

variable "create_legacy_dynamodb_lock_table" {
  description = "Create the deprecated DynamoDB lock table only for older Terraform clients. Current roots use S3 native lock files."
  type        = bool
  default     = false
}

variable "enable_kms_encryption" {
  type        = bool
  description = "Encrypt new Terraform state objects with a customer-managed KMS key."
  default     = true
}

variable "noncurrent_version_retention_days" {
  type        = number
  description = "Days to retain previous Terraform state object versions."
  default     = 90
}

variable "tags" {
  type = map(string)
  default = {
    Project       = "astronomy-shop"
    Application   = "astronomy-shop"
    Service       = "astronomy-shop"
    Component     = "remote-state"
    Environment   = "bootstrap"
    ManagedBy     = "Terraform"
    TerraformRoot = "bootstrap/remote-state"
    Repository    = "astronomy-shop-gitops"
    Owner         = "cloudnative-platform-lab"
    Region        = "ap-south-1"
    Purpose       = "remote-state"
  }
}
