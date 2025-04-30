# 🏗️ Infraestructura de Microservicios en Azure

Este repositorio contiene la infraestructura como código (IaC) utilizando Terraform para desplegar una arquitectura de microservicios en Azure Container Apps.

![Arquitectura de Microservicios](../microservice-app-example/arch-img/Microservices.png)

## 📑 Tabla de Contenidos

- [Descripción de la Arquitectura](#descripción-de-la-arquitectura)
- [Infraestructura en Azure Container Apps](#infraestructura-en-azure-container-apps)
- [Estructura de Archivos Terraform](#estructura-de-archivos-terraform)
- [Detalles Técnicos de la Implementación](#detalles-técnicos-de-la-implementación)
- [Pipeline CI/CD en Azure DevOps](#pipeline-cicd-en-azure-devops)
- [Configuración y Despliegue](#configuración-y-despliegue)
- [Seguridad y Mejores Prácticas](#seguridad-y-mejores-prácticas)
- [Monitoreo y Observabilidad](#monitoreo-y-observabilidad)
- [Optimización y Escalabilidad](#optimización-y-escalabilidad)
- [Referencias y Recursos](#referencias-y-recursos)

## 🏢 Descripción de la Arquitectura

La infraestructura despliega un sistema de microservicios completo en Azure Container Apps con los siguientes componentes:

### Componentes Principales

| Servicio | Tecnología | Descripción |
|----------|------------|-------------|
| Frontend | Vue.js | Interfaz de usuario de la aplicación de TODOs |
| Auth API | Go | Servicio de autenticación y gestión de tokens JWT |
| Users API | Java Spring Boot | Gestión de información de usuarios |
| TODOs API | Node.js | Gestión de las tareas pendientes |
| Log Processor | Python | Procesamiento de logs y auditoría |

### Recursos de Azure

| Recurso | Propósito | Configuración |
|---------|-----------|---------------|
| Azure Container Apps | Entorno serverless para ejecutar microservicios containerizados | Escalado automático, 1-3 réplicas por servicio |
| Azure Container Registry | Almacenamiento de imágenes Docker para los microservicios | SKU Basic con autenticación admin |
| API Management | API Gateway para gestionar, asegurar y monitorizar las APIs | Nivel Consumption para optimizar costos |
| Redis Cache | Caché en memoria y sistema de mensajería pub/sub | Tier Basic, familia C, capacidad 0 |
| Log Analytics Workspace | Centralización de logs y monitoreo | Retención de 30 días, SKU PerGB2018 |

## 🔌 Infraestructura en Azure Container Apps

Azure Container Apps proporciona un entorno "serverless" para ejecutar aplicaciones contenerizadas con las siguientes características:

- **Escalado automático**: Basado en carga, con soporte para escalar a cero
- **Microservicios**: Ejecución de servicios independientes en un entorno compartido

- **Ingress**: Configuración de acceso externo e interno
- **Secrets**: Manejo seguro de credenciales y configuraciones sensibles

En nuestro caso, cada microservicio se despliega como una Container App independiente con:
- Configuración específica de recursos (CPU, memoria)
- Variables de entorno para configuración
- Escalado automático basado en carga
- Conectividad segura entre servicios

## 📂 Estructura de Archivos Terraform

### main.tf
Este archivo define los recursos principales de la infraestructura:

```
terraform {
  required_providers {
    azurerm = { ... }
    random = { ... }
  }
}

# Proveedor Azure
provider "azurerm" { ... }

# Variables y recursos base
resource "random_string" "suffix" { ... }
resource "azurerm_resource_group" "rg" { ... }

# Container Registry
resource "azurerm_container_registry" "acr" { ... }

# Log Analytics
resource "azurerm_log_analytics_workspace" "workspace" { ... }

# Container App Environment
resource "azurerm_container_app_environment" "env" { ... }

# API Management
resource "azurerm_api_management" "apim" { ... }
resource "azurerm_api_management_api" "users_api" { ... }
resource "azurerm_api_management_api" "auth_api" { ... }
resource "azurerm_api_management_api" "todos_api" { ... }

# API Operations
resource "azurerm_api_management_api_operation" "..." { ... }

# Redis Cache
resource "azurerm_redis_cache" "redis" { ... }
```

### container-apps.tf
Contiene la definición de las Container Apps para cada microservicio:

```
# Auth API (Go)
resource "azurerm_container_app" "auth_api" { ... }

# Users API (Java Spring Boot)
resource "azurerm_container_app" "users_api" { ... }

# TODOs API (Node.js)
resource "azurerm_container_app" "todos_api" { ... }

# Log Message Processor (Python)
resource "azurerm_container_app" "log_processor" { ... }

# Frontend (Vue.js)
resource "azurerm_container_app" "frontend" { ... }
```

### outputs.tf
Define las salidas (outputs) del despliegue de Terraform:

```
output "frontend_url" { ... }
output "auth_api_url" { ... }
output "users_api_url" { ... }
output "todos_api_url" { ... }
output "api_gateway_url" { ... }
output "acr_login_server" { ... }
```

## 🔧 Detalles Técnicos de la Implementación

### 1. Gestión de Secretos

Los secretos como contraseñas y claves de acceso se manejan utilizando el recurso `secret` de Container Apps:

```hcl
secret {
  name  = "registry-password"
  value = azurerm_container_registry.acr.admin_password
}
```

### 2. Configuración de Networking

Cada Container App utiliza ingress para exponer servicios:

```hcl
ingress {
  external_enabled = true
  target_port      = 8000
  traffic_weight {
    latest_revision = true
    percentage      = 100
  }
}
```

### 3. Interconexión entre Servicios

Los servicios se comunican entre sí usando sus FQDN (Fully Qualified Domain Names) internos:

```hcl
env {
  name  = "USERS_API_ADDRESS"
  value = "https://${azurerm_container_app.users_api.ingress[0].fqdn}"
}
```

### 4. Gestión de API mediante API Management

Todas las APIs están expuestas a través de Azure API Management:

```hcl
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
```

### 5. Definición de Operaciones de API

```hcl
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
```

### 6. Integración con Redis Cache

Los servicios utilizan Azure Redis Cache para caché y mensajería:

```hcl
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
```

### 7. Configuración de Escalabilidad

Cada servicio tiene configuraciones específicas de escalado:

```hcl
template {
  # ...
  min_replicas = 1
  max_replicas = 3
}
```

## 🔄 Pipeline CI/CD en Azure DevOps

El repositorio incluye un pipeline completo definido en `azure-pipelines.yml` que automatiza el despliegue de la infraestructura:

### Etapas del Pipeline

#### 1. Validación de Infraestructura
```yaml
- stage: Validate
  displayName: 'Validar Infraestructura'
  jobs:
  - job: ValidateTerraform
    steps:
    - task: CopyFiles@2 # Copia archivos al directorio de trabajo
    - task: TerraformInstaller@0 # Instala Terraform
    - task: TerraformTaskV4@4 # Inicializa Terraform
    - task: TerraformTaskV4@4 # Valida la configuración
    - task: TerraformTaskV4@4 # Genera el plan de ejecución
    - task: PublishPipelineArtifact@1 # Publica artefactos para uso posterior
```

#### 2. Despliegue de Infraestructura
```yaml
- stage: Deploy
  displayName: 'Desplegar Infraestructura'
  dependsOn: Validate
  jobs:
  - deployment: DeployTerraform
    environment: 'Production' # Requiere aprobación manual
    strategy:
      runOnce:
        deploy:
          steps:
          - task: DownloadPipelineArtifact@2 # Descarga artefactos del stage anterior
          - task: TerraformTaskV4@4 # Inicializa Terraform
          - task: TerraformTaskV4@4 # Aplica cambios (terraform apply)
```

#### 3. Pruebas Post-Despliegue
```yaml
- stage: Test
  displayName: 'Pruebas Post-Despliegue'
  dependsOn: Deploy
  jobs:
  - job: TestInfrastructure
    steps:
    - task: TerraformTaskV4@4 # Obtiene outputs de Terraform
    - bash: # Script para verificar disponibilidad de endpoints
```

### Características Clave del Pipeline

- **Backend Remoto**: Utiliza Azure Storage como backend remoto para el estado de Terraform
- **Validación Previa**: Ejecuta `terraform validate` y `terraform plan` antes de aplicar cambios
- **Aprobación Manual**: Requiere aprobación para el despliegue en ambiente de producción
- **Pruebas Automáticas**: Verifica que los endpoints estén disponibles después del despliegue
- **Artefactos**: Publica y comparte archivos entre etapas del pipeline

## ⚙️ Configuración y Despliegue

### Requisitos Previos

- [Azure CLI](https://docs.microsoft.com/es-es/cli/azure/install-azure-cli) instalado
- [Terraform](https://www.terraform.io/downloads.html) (versión 1.0 o superior)
- Cuenta de Azure con permisos para crear recursos
- [Azure DevOps](https://dev.azure.com) para CI/CD (o configurar GitHub Actions)

### Configuración Inicial

1. Inicia sesión en Azure:
```shell
az login
```

2. Crea un grupo de recursos para el estado de Terraform (si no existe):
```shell
az group create --name rg-microservice-app --location eastus
```

3. Crea una cuenta de almacenamiento para el estado de Terraform:
```shell
az storage account create --name tfstatemicroapp --resource-group rg-microservice-app --location eastus --sku Standard_LRS
```

4. Crea un contenedor en la cuenta de almacenamiento:
```shell
az storage container create --name tfstate --account-name tfstatemicroapp
```

5. Crea un archivo `backend.tf` para configurar el backend remoto:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name   = "rg-microservice-app"
    storage_account_name  = "tfstatemicroapp"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}
```

### Despliegue Manual

Para desplegar manualmente la infraestructura:

1. Inicializa Terraform con el backend remoto:
```shell
terraform init
```

2. Ejecuta un plan para verificar los cambios:
```shell
terraform plan -out=tfplan
```

3. Aplica los cambios:
```shell
terraform apply "tfplan"
```

4. Para ver los outputs después del despliegue:
```shell
terraform output     
```

### Despliegue con Azure DevOps

1. Crea un proyecto en Azure DevOps
2. Configura una conexión de servicio a Azure llamada `AzureServiceConnect`
3. Importa el repositorio Git
4. Crea un pipeline basado en el archivo `azure-pipelines.yml`
5. Crea un ambiente llamado `Production` para las aprobaciones
6. Ejecuta el pipeline

## 🔒 Seguridad y Mejores Prácticas

Esta infraestructura implementa las siguientes medidas de seguridad y mejores prácticas:

### Seguridad

- **Secretos Seguros**: Las credenciales se almacenan como secretos en Container Apps
- **HTTPS**: Todas las comunicaciones externas utilizan TLS 1.2 o superior
- **API Management**: Control de acceso centralizado para todas las APIs
- **Autenticación Redis**: Protección de acceso mediante contraseñas


### Buenas Prácticas de IaC

- **Modularidad**: Separación de recursos en archivos lógicos
- **Nombres Dinámicos**: Uso de sufijos aleatorios para garantizar uniqueness
- **Variables**: Uso de variables para facilitar la configuración
- **Outputs**: Exportación de información relevante para facilitar el acceso posterior
- **Dependencias**: Definición explícita de dependencias entre recursos

### Mejores Prácticas de Azure

- **Resource Tags**: Para organización y gobierno
- **Log Analytics**: Centralización de logs para análisis
- **Consumption Tier**: Uso de tiers de consumo para optimizar costos
- **Container Apps Environment**: Entorno compartido para todos los servicios
- **API Management**: Gestión centralizada de APIs

## 📊 Monitoreo y Observabilidad

La infraestructura incluye componentes para monitoreo y observabilidad:

### Log Analytics Workspace

```hcl
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "law-microapp-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
```

## 📚 Referencias y Recursos

- [Azure Container Apps](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure API Management](https://docs.microsoft.com/en-us/azure/api-management/)
- [Azure Redis Cache](https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/)
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Azure DevOps Pipelines para Terraform](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/terraform)

