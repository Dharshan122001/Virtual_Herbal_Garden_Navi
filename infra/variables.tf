variable "db_password" {
  type      = string
  sensitive = true
}

variable "my_ip" {
  type = string
}

variable "frontend_tag" {
  type    = string
  default = "latest"
}

variable "plant_tag" {
  type    = string
  default = "latest"
}

variable "auth_tag" {
  type    = string
  default = "latest"
}

variable "ai_tag" {
  type    = string
  default = "latest"
}