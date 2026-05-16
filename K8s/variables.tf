variable "db_password" {
  type      = string
  sensitive = true
}
variable "azure_devops_pat" {
  type      = string
  sensitive = true
}

# --- LEGACY DATADOG VARIABLES ---
# We give these a default empty string so Terraform doesn't 
# stop and ask for them since they are commented out in secrets.tfvars

variable "datadog_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "datadog_site" {
  type    = string
  default = "datadoghq.com"
}

variable "datadog_rum_app_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "datadog_rum_client_token" {
  type      = string
  sensitive = true
  default   = ""
}