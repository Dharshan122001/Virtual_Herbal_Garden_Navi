variable "db_password" {
  type      = string
  sensitive = true
}
variable "azure_devops_pat" {
  type      = string
  sensitive = true
}

variable "datadog_api_key" {
  type      = string
  sensitive = true
}

variable "datadog_site" {
  type    = string
  default = "datadoghq.com"
}
