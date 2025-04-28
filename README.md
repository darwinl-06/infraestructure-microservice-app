# Infraestructura de Microservicios en Azure

Este repositorio contiene la infraestructura como código (IaC) utilizando Terraform para desplegar una arquitectura de microservicios en Azure Container Apps.

![Arquitectura de Microservicios](../microservice-app-example/arch-img/Microservices.png)

## Descripción de la Arquitectura

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

| Recurso | Propósito |
|---------|-----------|
| Azure Container Apps | Entorno serverless para ejecutar microservicios containerizados |
| Azure Container Registry | Almacenamiento de imágenes Docker para los microservicios |
| API Management | API Gateway para gestionar, asegurar y monitorizar las APIs |
| Redis Cache | Caché en memoria y sistema de mensajería pub/sub |
| Log Analytics Workspace | Centralización de logs y monitoreo |

## Requisitos Previos

- [Azure CLI](https://docs.microsoft.com/es-es/cli/azure/install-azure-cli) instalado
- [Terraform](https://www.terraform.io/downloads.html) (versión 1.0 o superior)
- Cuenta de Azure con permisos para crear recursos
- [Azure DevOps](https://dev.azure.com) para CI/CD (o configurar GitHub Actions)

## Configuración Inicial

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

5. Obtén la clave de acceso a la cuenta de almacenamiento:
```shell
az storage account keys list --account-name tfstatemicroapp --resource-group rg-microservice-app
```

## Configuración de Backend de Terraform

Crea un archivo `backend.tf` con el siguiente contenido:

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

## Variables de Configuración

Las principales variables configurables se encuentran en `main.tf`:

| Variable | Descripción | Valor por defecto |
|----------|-------------|------------------|
| location | Región de Azure donde se despliegan los recursos | eastus |
| resource_group_name | Nombre del grupo de recursos | rg-microservice-app |

## Despliegue Manual

Para desplegar manualmente la infraestructura:

1. Inicializa Terraform:
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

## Despliegue con Azure DevOps

El pipeline de Azure DevOps automatiza el despliegue de la infraestructura:

1. El archivo `azure-pipelines.yml` define el pipeline completo
2. El pipeline incluye etapas de validación, despliegue y pruebas
3. Para configurarlo en Azure DevOps:
   - Crea una conexión de servicio de Azure llamada `AzureServiceConnect`
   - Crea un pipeline que apunte al archivo `azure-pipelines.yml`
   - Crea un entorno llamado `Production` para las aprobaciones

## Estructura del Código

- `main.tf`: Definición de proveedores, variables y recursos básicos
- `container-apps.tf`: Definición de todas las Container Apps y sus configuraciones
- `outputs.tf`: Outputs generados después del despliegue
- `azure-pipelines.yml`: Pipeline CI/CD para Azure DevOps

## Seguridad

La infraestructura incluye las siguientes medidas de seguridad:

- Acceso a Container Registry securizado con credenciales
- API Management para controlar el acceso a las APIs
- Almacenamiento de secretos mediante secrets de Container Apps
- TLS habilitado para todas las comunicaciones externas
- Uso de Redis Cache con autenticación habilitada

## Mejores Prácticas Implementadas

- **Escalabilidad**: Configuración de auto-escalado para cada Container App
- **Confiabilidad**: Réplicas mínimas configuradas para alta disponibilidad
- **Seguridad**: Configuración de secretos para credenciales sensibles
- **Eficiencia**: Configuración de recursos (CPU/memoria) optimizada para cada servicio
- **Observabilidad**: Centralización de logs en Log Analytics Workspace
- **IaC**: Toda la infraestructura está definida como código con Terraform

## Outputs Importantes

El despliegue proporciona varios outputs importantes:

- URLs de todos los servicios (frontend, auth-api, users-api, todos-api)
- URL del API Gateway
- Credenciales del Container Registry
- Configuración de Redis Cache

Para ver los outputs después del despliegue:
```shell
terraform output
```

Para ver un output específico, incluyendo valores sensibles:
```shell
terraform output -raw acr_admin_password
```

## Monitoreo y Logging

Todos los logs de las Container Apps se envían a Log Analytics Workspace, donde pueden ser consultados y analizados. Para acceder a ellos:

1. Ve al grupo de recursos en el portal de Azure
2. Selecciona el recurso de Log Analytics Workspace
3. Utiliza "Logs" para ejecutar consultas

## Limpieza de Recursos

Para eliminar todos los recursos desplegados:
```shell
terraform destroy
```

## Referencias

- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure API Management](https://docs.microsoft.com/en-us/azure/api-management/)
- [Azure Redis Cache](https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/)