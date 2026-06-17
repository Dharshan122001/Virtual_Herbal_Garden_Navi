variable "resource_group_name" {
  type        = string
  description = "The target Azure Resource Group name."
}

variable "location" {
  type        = string
  description = "The target Azure region location mapping."
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "The administrative password for the PostgreSQL flexible server."
}

variable "common_tags" {
  type        = map(string)
  description = "Metadata tags applied to all provisioned infrastructure components."
}