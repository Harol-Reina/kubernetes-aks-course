# 🚀 Curso: Fundamentos de Kubernetes y su Implementación en Azure (AKS)

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326ce5.svg?&style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Azure](https://img.shields.io/badge/Microsoft_Azure-0089D0?style=for-the-badge&logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)
[![Docker](https://img.shields.io/badge/Docker-2CA5E0?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)

## 📋 Información General

**Duración**: 32 horas  
**Modalidad**: Teórico – Práctico (laboratorios en Azure)  
**Nivel**: Principiante – Intermedio  
**Plataforma**: Microsoft Azure (VMs y AKS)

## 🎯 Objetivos del Curso

Este curso te llevará desde los fundamentos de la contenerización hasta la administración avanzada de clústeres de Kubernetes en Azure, proporcionándote las habilidades necesarias para:

- Comprender y aplicar conceptos de virtualización y contenerización
- Dominar Docker y la construcción de imágenes
- Diseñar e implementar arquitecturas de Kubernetes
- Administrar clústeres AKS en producción
- Implementar seguridad, monitoreo y alta disponibilidad
- Crear pipelines CI/CD para Kubernetes

## 📚 Estructura del Curso

### [Área 1 - Fundamentos de Virtualización, Contenerización y Docker](./area-1-fundamentos-docker/)
**Duración**: 6 horas

- Virtualización tradicional vs contenerización
- Fundamentos de Docker
- Construcción de imágenes y Dockerfile
- Docker Compose y orquestación básica
- Azure Container Registry (ACR)

### [Área 2 - Fundamentos y Arquitectura de Kubernetes](./area-2-arquitectura-kubernetes/)
**Duración**: 8 horas

- Arquitectura de Kubernetes
- Componentes del clúster
- Objetos principales: Pods, Services, Deployments
- Networking y gestión de configuración
- Controladores Ingress

### [Área 3 - Operación, Seguridad y Almacenamiento](./area-3-operacion-seguridad/)
**Duración**: 9 horas

- Gestión de clústeres AKS
- RBAC y control de acceso
- Network Policies y seguridad
- Almacenamiento persistente
- Integración con Azure Key Vault

### [Área 4 - Observabilidad, Alta Disponibilidad e Integración](./area-4-observabilidad-ha/)
**Duración**: 9 horas

- Logging y observabilidad
- Monitoreo con Prometheus y Grafana
- Alta disponibilidad y autoescalado
- CI/CD y GitOps
- Troubleshooting avanzado

### [Proyecto Final](./proyecto-final/)
Aplicación de 3 capas con todas las tecnologías aprendidas

## 🛠️ Prerrequisitos

### Conocimientos Técnicos
- Conceptos básicos de Linux y línea de comandos
- Fundamentos de redes (TCP/IP, DNS, HTTP)
- Experiencia básica con sistemas distribuidos (deseable)

### Recursos Necesarios
- **Suscripción de Azure** (se puede usar Azure Free Tier)
- **Herramientas locales**:
  - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
  - [kubectl](https://kubernetes.io/docs/tasks/tools/)
  - [Docker Desktop](https://www.docker.com/products/docker-desktop) (opcional para desarrollo local)
  - [Visual Studio Code](https://code.visualstudio.com/) con extensiones de Kubernetes
  - [Helm](https://helm.sh/docs/intro/install/)

### Configuración Inicial
```bash
# Instalar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Instalar Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

## 🧪 Laboratorios Prácticos

Cada área incluye laboratorios hands-on donde aplicarás los conceptos aprendidos:

- **15+ laboratorios prácticos**
- **Entornos reales en Azure**
- **Código y configuraciones de ejemplo**
- **Casos de uso del mundo real**

## 📖 Materiales de Apoyo

- [**Ejemplos de código**](./ejemplos/): Archivos YAML, Dockerfiles y scripts
- [**Cheat Sheets**](./recursos/cheat-sheets/): Comandos esenciales y referencias rápidas
- [**Glossario**](./recursos/glossario.md): Términos y conceptos clave
- [**Recursos adicionales**](./recursos/): Enlaces, documentación y herramientas

## 🚀 Cómo Empezar

1. **Clona este repositorio**:
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd kubernetes-aks-course
   ```

2. **Configura tu entorno Azure**:
   ```bash
   az login
   az account set --subscription "<TU_SUBSCRIPTION_ID>"
   ```

3. **Comienza con el Área 1**:
   ```bash
   cd area-1-fundamentos-docker
   ```

4. **Sigue la guía paso a paso** en cada módulo

## 📝 Certificación y Evaluación

Al completar este curso estarás preparado para:

- **Certified Kubernetes Administrator (CKA)**
- **Azure Kubernetes Service (AKS) certifications**
- **Certified Kubernetes Application Developer (CKAD)**

### Criterios de Evaluación
- Laboratorios prácticos completados (70%)
- Proyecto final (30%)
- Participación en discusiones técnicas

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas! Si encuentras errores o tienes sugerencias:

1. Fork del repositorio
2. Crea una branch para tu feature
3. Commit tus cambios
4. Push a la branch
5. Abre un Pull Request

## 📞 Soporte

- **Issues**: Reporta problemas en la sección de Issues
- **Discusiones**: Únete a las discusiones técnicas
- **Email**: [contacto@ejemplo.com]

## 📄 Licencia

Este curso está bajo la licencia [MIT](LICENSE) - consulta el archivo LICENSE para más detalles.

## 🙏 Agradecimientos

- Comunidad de Kubernetes
- Microsoft Azure Team
- CNCF (Cloud Native Computing Foundation)
- Todos los contributors de este proyecto

---

⭐ **¡No olvides dar una estrella a este repositorio si te resulta útil!**

**Última actualización**: Noviembre 2025