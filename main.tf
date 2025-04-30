terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  skip_provider_registration = true
}

provider "random" {}

# Variables
variable "location" {
  description = "La región de Azure donde se desplegarán los recursos"
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  default     = "rg-microservice-app"
}

# Generador de cadena aleatoria para nombres únicos
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Grupo de recursos
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "acrmicroapp${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Log Analytics Workspace para Container Apps
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "law-microapp-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container App Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "env-microapp-${random_string.suffix.result}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
}

# API Management (API Gateway)
resource "azurerm_api_management" "apim" {
  name                = "apim-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Icesi University"
  publisher_email     = "darwinlenis.06@gmail.com"
  sku_name           = "Consumption_0"  # Capa de consumo (incluye llamadas gratuitas)
}

# Create Users API in API Management
resource "azurerm_api_management_api" "users_api" {
  name                = "users-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Users API"
  path                = "users"
  protocols           = ["https"]
  service_url         = "https://${azurerm_container_app.users_api.ingress[0].fqdn}"
}

# Create Auth API in API Management
resource "azurerm_api_management_api" "auth_api" {
  name                = "auth-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Auth API"
  path                = "auth"
  protocols           = ["https"]
  service_url         = "https://${azurerm_container_app.auth_api.ingress[0].fqdn}"
}

# Create Todos API in API Management
resource "azurerm_api_management_api" "todos_api" {
  name                = "todos-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Todos API"
  path                = "todos"
  protocols           = ["https"]
  service_url         = "https://${azurerm_container_app.todos_api.ingress[0].fqdn}"
}

# Users API operations
resource "azurerm_api_management_api_operation" "get_all_users" {
  operation_id        = "get-all-users"
  api_name            = azurerm_api_management_api.users_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get all users"
  method              = "GET"
  url_template        = "users/"
  description         = "Get all users"
}

resource "azurerm_api_management_api_operation" "get_user_by_name" {
  operation_id        = "get-user-by-name"
  api_name            = azurerm_api_management_api.users_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get user by name"
  method              = "GET"
  url_template        = "users/{username}"
  description         = "Get a user by name"
  
  template_parameter {
    name        = "username"
    required    = true
    type        = "string"
    description = "Username"
  }
}

# Auth API operations
resource "azurerm_api_management_api_operation" "login" {
  operation_id        = "login"
  api_name            = azurerm_api_management_api.auth_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Login"
  method              = "POST"
  url_template        = "/login"
  description         = "Login and get JWT token"
}

# Todos API operations
resource "azurerm_api_management_api_operation" "get_todos" {
  operation_id        = "get-todos"
  api_name            = azurerm_api_management_api.todos_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Get all todos"
  method              = "GET"
  url_template        = "todos/"
  description         = "Get all todos for a user"
}

resource "azurerm_api_management_api_operation" "create_todo" {
  operation_id        = "create-todo"
  api_name            = azurerm_api_management_api.todos_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Create todo"
  method              = "POST"
  url_template        = "todos/"
  description         = "Create new todo"
}

resource "azurerm_api_management_api_operation" "delete_todo" {
  operation_id        = "delete-todo"
  api_name            = azurerm_api_management_api.todos_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Delete todo"
  method              = "DELETE"
  url_template        = "todos/{taskId}"
  description         = "Delete a todo by ID"
  
  template_parameter {
    name        = "taskId"
    required    = true
    type        = "string"
    description = "Task ID"
  }
}

# Azure Redis Cache (Comentado para evitar demoras en el despliegue)
resource "azurerm_redis_cache" "redis" {
  name                = "redis-microapp-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = true
  minimum_tls_version = "1.2"
}
