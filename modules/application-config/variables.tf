variable "secret_arn" { type = string }
variable "config" {
  type      = map(string)
  sensitive = true
}
