# Container App para Auth API (Go)
resource "azurerm_container_app" "auth_api" {
  name                         = "auth-api"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.acr.admin_password
  }

  template {
    container {
      name   = "auth-api"
      image  = "golang:1.18-alpine"  # Imagen base inicial que será reemplazada por el pipeline
      cpu    = "0.5"
      memory = "1Gi"
      
      # Puertos y variables de entorno
      env {
        name  = "PORT"
        value = "8000"
      }
      env {
        name  = "AUTH_API_PORT"
        value = "8000"
      }
      env {
        name  = "USERS_API_ADDRESS"
        value = "https://${azurerm_container_app.users_api.ingress[0].fqdn}"
      }
      env {
        name  = "JWT_SECRET"
        value = "PRFT"
      }
    }
    min_replicas = 1
    max_replicas = 3
  }
  
  ingress {
    external_enabled = true
    target_port      = 8000
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# Container App para Users API (Java Spring Boot)
resource "azurerm_container_app" "users_api" {
  name                         = "users-api"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.acr.admin_password
  }

  template {
    container {
      name   = "users-api"
      image  = "openjdk:8-jdk-alpine"  # Imagen base inicial que será reemplazada por el pipeline
      cpu    = "0.5"
      memory = "1Gi"
      
      env {
        name  = "SERVER_PORT"
        value = "8083"
      }
      env {
        name  = "JWT_SECRET"
        value = "PRFT"
      }
    }
    min_replicas = 1
    max_replicas = 3
  }
  
  ingress {
    external_enabled = true
    target_port      = 8083
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# Container App para TODOs API (Node.js)
resource "azurerm_container_app" "todos_api" {
  name                         = "todos-api"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.acr.admin_password
  }

  template {
    container {
      name   = "todos-api"
      image  = "node:14-alpine"  # Imagen base inicial que será reemplazada por el pipeline
      cpu    = "0.5"
      memory = "1Gi"
      
      env {
        name  = "PORT"
        value = "8082"
      }
      env {
        name  = "TODO_API_PORT"
        value = "8082"
      }
      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.redis.hostname
      }
      env {
        name  = "REDIS_PASSWORD"
        value = azurerm_redis_cache.redis.primary_access_key
      }
      env {
        name  = "REDIS_PORT"
        value = "6379"
      }
      env {
        name  = "REDIS_CHANNEL"
        value = "log_channel"
      }
      env {
        name  = "JWT_SECRET"
        value = "PRFT"
      }  
      
    }
    min_replicas = 1
    max_replicas = 3
  }
  
  ingress {
    external_enabled = true
    target_port      = 8082
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  depends_on = [azurerm_container_app.auth_api]
}

# Container App para Log Message Processor (Python)
resource "azurerm_container_app" "log_processor" {
  name                         = "log-processor"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.acr.admin_password
  }

  template {
    container {
      name   = "log-processor"
      image  = "python:3.9-slim"  # Imagen base inicial que será reemplazada por el pipeline
      cpu    = "0.25"
      memory = "0.5Gi"
      
      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.redis.hostname
      }
      env {
        name  = "REDIS_PORT"
        value = "6379"
      }
      env {
        name  = "REDIS_CHANNEL"
        value = "log_channel"
      }
      env {
        name  = "REDIS_PASSWORD"
        value = azurerm_redis_cache.redis.primary_access_key
      }
      # Variables de entorno para Redis comentadas
      
    }
    min_replicas = 1
    max_replicas = 2
  }
}

# Container App para Frontend (Vue.js)
resource "azurerm_container_app" "frontend" {
  name                         = "frontend"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "registry-password"
  }

  secret {
    name  = "registry-password"
    value = azurerm_container_registry.acr.admin_password
  }

  template {
    container {
      name   = "frontend"
      image  = "node:14-alpine"  # Imagen base inicial que será reemplazada por el pipeline
      cpu    = "0.5"
      memory = "1Gi"
      
      env {
        name  = "PORT"
        value = "8080"
      }
      env {
        name  = "AUTH_API_ADDRESS"
        value = "${azurerm_api_management.apim.gateway_url}/auth"
      }
      env {
        name  = "TODOS_API_ADDRESS"
        value = "${azurerm_api_management.apim.gateway_url}/todos"
      }
      env {
        name  = "APIM_SUBSCRIPTION_KEY"
        value = "9e4cb027af834c0e88f7a83bd51927df"  
      }

    }
    min_replicas = 1
    max_replicas = 3
  }
  
  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  depends_on = [
    azurerm_container_app.auth_api,
    azurerm_container_app.todos_api,
    azurerm_container_app.users_api
  ]
}