# 1. Required Providers Block
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  backend "azurerm" {} 
}

# 2. Provider Configuration Block
provider "azurerm" {
  features {}
}

# --- 1. Reference Existing Infrastructure ---
data "azurerm_resource_group" "existing_rg" {
  name = "Darshan.k_lean_rg"
}

# --- 2. Centralized Tags & Shared Backend Config ---
locals {
  location = "canadacentral"
  common_tags = {
    owner   = "dharshan.k@navikenz.com"
    project = "Terraform-vhg-poc"
    cost    = "none"
  }

  shared_backend_vars = {
    "ALGORITHM"           = "HS256"
    "GEMINI_API_KEY"      = "AIzaSyDU2IRX8vjA5dtEfcuJ6IRAKuv4Ij1CBL4"
    "GROQ_API_KEY"        = "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"
    "GMAIL_CLIENT_ID"     = "491680937929-m88h1v3rkremor2v6025aes8l2egqufd.apps.googleusercontent.com"
    "GMAIL_CLIENT_SECRET" = "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"
    "GMAIL_REFRESH_TOKEN" = "1//0gNUjID8oBv9JCgYIARAAGBASNwF-L9IrkeSzw_VBE71GWQIe4JP-lOM0FYZvbSQAWSfOCPt_Fn4_JCaBvAuCfKBKb-sMagwih8k"
    "MAIL_SERVER"         = "smtp.gmail.com"
    "MAIL_PORT"           = "587"
    "MAIL_USERNAME"       = "dharshan122001@gmail.com"
    "MAIL_FROM"           = "dharshan122001@gmail.com"
    "MAIL_PASSWORD"       = "nxwgqsnu jhfk khof"
    "MAIL_STARTTLS"       = "True"
    "MAIL_SSL_TLS"        = "False"
    "PLANTNET_API_KEY"    = "2b10axG37F0YebW32fCdNG7Q"
    "PYTHON_VERSION"      = "3.10.13"
    "SECRET_KEY"          = "finiteloop_secret_secure_key_123"
    "DOCKER_ENABLE_CI"    = "true"
  }
}

# --- 3. App Service Plan ---
resource "azurerm_service_plan" "vhg_plan" {
  name                = "vhg-service-plan-terraform"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  location            = local.location
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = local.common_tags
}

# --- 4. PostgreSQL Flexible Server ---
resource "azurerm_postgresql_flexible_server" "vhg_db" {
  name                   = "vhg-db-server-darshan-terraform-v1" 
  resource_group_name    = data.azurerm_resource_group.existing_rg.name
  location               = local.location
  version                = "13"
  administrator_login    = "vhgadmin_terraform"
  administrator_password = var.db_password 
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  tags                   = local.common_tags
}

# --- NEW: FIREWALL RULES ---

# Rule 1: Allow all Azure Services (Required for App Services to talk to DB)
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.vhg_db.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Rule 2: Allow Your Mac (Update start/end with your actual Public IP)
# You can find your IP at https://ifconfig.me/
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_my_mac" {
  name             = "allow-local-mac"
  server_id        = azurerm_postgresql_flexible_server.vhg_db.id
  start_ip_address = "49.207.200.123" # <--- REPLACE WITH YOUR IP
  end_ip_address   = "49.207.200.123" # <--- REPLACE WITH YOUR IP
}

# --- 5. PLANT BACKEND ---
resource "azurerm_linux_web_app" "plant_backend" {
  name                = "herbal-garden-plant-terraform"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  location            = local.location
  service_plan_id     = azurerm_service_plan.vhg_plan.id
  tags                = local.common_tags

  site_config {
    application_stack {
      docker_image_name   = "dharshan3690/plant-service:${var.plant_tag}"
      docker_registry_url = "https://index.docker.io"
    }
  }

  app_settings = merge(local.shared_backend_vars, {
    "WEBSITES_PORT" = "8005"
    "DATABASE_URL"  = "postgresql://vhgadmin_terraform:${var.db_password}@${azurerm_postgresql_flexible_server.vhg_db.fqdn}:5432/postgres?sslmode=require"
    "CORS_ORIGINS"  = "https://herbal-garden-frontend-terraform.azurewebsites.net"
  })
}

# --- 6. AUTH BACKEND ---
resource "azurerm_linux_web_app" "auth_backend" {
  name                = "herbal-garden-auth-terraform"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  location            = local.location
  service_plan_id     = azurerm_service_plan.vhg_plan.id
  tags                = local.common_tags

  site_config {
    application_stack {
      docker_image_name   = "dharshan3690/auth-service:${var.auth_tag}"
      docker_registry_url = "https://index.docker.io"
    }
  }

  app_settings = merge(local.shared_backend_vars, {
    "WEBSITES_PORT" = "8006"
    "DATABASE_URL"  = "postgresql://vhgadmin_terraform:${var.db_password}@${azurerm_postgresql_flexible_server.vhg_db.fqdn}:5432/postgres?sslmode=require"
    "CORS_ORIGINS"  = "https://herbal-garden-frontend-terraform.azurewebsites.net"
  })
}

# --- 7. AI BACKEND ---
resource "azurerm_linux_web_app" "ai_backend" {
  name                = "herbal-garden-ai-terraform"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  location            = local.location
  service_plan_id     = azurerm_service_plan.vhg_plan.id
  tags                = local.common_tags

  site_config {
    application_stack {
      docker_image_name   = "dharshan3690/ai-service:${var.ai_tag}"
      docker_registry_url = "https://index.docker.io"
    }
  }

  app_settings = merge(local.shared_backend_vars, {
    "WEBSITES_PORT" = "8007"
    "DATABASE_URL"  = "postgresql://vhgadmin_terraform:${var.db_password}@${azurerm_postgresql_flexible_server.vhg_db.fqdn}:5432/postgres?sslmode=require"
    "CORS_ORIGINS"  = "https://herbal-garden-frontend-terraform.azurewebsites.net"
  })
}

# --- 8. FRONTEND ---
resource "azurerm_linux_web_app" "frontend" {
  name                = "herbal-garden-frontend-terraform"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  location            = local.location
  service_plan_id     = azurerm_service_plan.vhg_plan.id
  tags                = local.common_tags

  site_config {
    application_stack {
      docker_image_name   = "dharshan3690/navi-frontend:${var.frontend_tag}"
      docker_registry_url = "https://index.docker.io"
    }
  }

  app_settings = {
    "VITE_PLANT_API_URL" = "https://${azurerm_linux_web_app.plant_backend.default_hostname}"
    "VITE_AUTH_API_URL"  = "https://${azurerm_linux_web_app.auth_backend.default_hostname}"
    "VITE_AI_API_URL"    = "https://${azurerm_linux_web_app.ai_backend.default_hostname}"
  }
  
}