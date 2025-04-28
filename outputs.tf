# Outputs para mostrar información después del despliegue

# Container Registry
output "acr_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "URL del Azure Container Registry"
}

output "acr_admin_username" {
  value       = azurerm_container_registry.acr.admin_username
  description = "Nombre de usuario administrador del ACR"
  sensitive   = false
}

output "acr_admin_password" {
  value       = azurerm_container_registry.acr.admin_password
  description = "Contraseña del administrador del ACR"
  sensitive   = true
}

# URLs de las Container Apps
output "auth_api_url" {
  value       = "https://${azurerm_container_app.auth_api.ingress[0].fqdn}"
  description = "URL pública del Auth API"
}

output "users_api_url" {
  value       = "https://${azurerm_container_app.users_api.ingress[0].fqdn}"
  description = "URL pública del Users API"
}

output "todos_api_url" {
  value       = "https://${azurerm_container_app.todos_api.ingress[0].fqdn}"
  description = "URL pública del TODOs API"
}

output "frontend_url" {
  value       = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
  description = "URL pública de la aplicación Frontend"
}

# URL del API Gateway (API Management)
output "api_gateway_url" {
  description = "URL del API Gateway para acceder a los servicios"
  value       = azurerm_api_management.apim.gateway_url
}

# Redis Cache outputs (comentados porque el recurso está comentado)
output "redis_hostname" {
  value       = azurerm_redis_cache.redis.hostname
  description = "Hostname de la instancia de Redis"
}

output "redis_port" {
  value       = azurerm_redis_cache.redis.port
  description = "Puerto de la instancia de Redis"
}

output "redis_primary_key" {
  value       = azurerm_redis_cache.redis.primary_access_key
  description = "Clave primaria de acceso a Redis"
  sensitive   = true
}