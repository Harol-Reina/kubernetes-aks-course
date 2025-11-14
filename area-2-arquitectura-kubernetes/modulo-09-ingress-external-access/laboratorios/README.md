# 🌍 Laboratorios - Ingress y Acceso Externo

Este módulo contiene laboratorios prácticos para dominar Ingress y acceso externo en Kubernetes.

## 📋 Índice de Laboratorios

### [Lab 01: Ingress Básico](./lab-01-ingress-basico/)
**Duración:** 60-75 minutos | **Dificultad:** ⭐⭐☆☆☆

Introducción a Ingress y configuración básica.

**Objetivos:**
- Instalar Ingress Controller (NGINX)
- Crear recursos Ingress básicos
- Configurar reglas de enrutamiento
- Probar acceso HTTP

---

### [Lab 02: Ingress TLS Avanzado](./lab-02-ingress-tls-avanzado/)
**Duración:** 90-120 minutos | **Dificultad:** ⭐⭐⭐⭐☆

Configuración de HTTPS y características avanzadas.

**Objetivos:**
- Configurar TLS/SSL
- Generar certificados
- Path-based routing
- Host-based routing

---

### [Lab 03: Ingress en Producción](./lab-03-ingress-produccion/)
**Duración:** 120-150 minutos | **Dificultad:** ⭐⭐⭐⭐⭐

Best practices y configuración para producción.

**Objetivos:**
- Rate limiting
- Authentication
- Monitoreo y logging
- High availability

---

## 🎯 Ruta de Aprendizaje Recomendada

1. **Nivel Básico** → Lab 01 (Ingress básico)
2. **Nivel Intermedio** → Lab 02 (TLS avanzado)
3. **Nivel Avanzado** → Lab 03 (Producción)

**Tiempo total estimado:** 5-6 horas

## 📚 Conceptos Clave

### Ingress vs Service
- **Service**: Expone pods dentro del cluster
- **Ingress**: Expone HTTP/HTTPS al exterior
- **Ingress Controller**: Implementa las reglas de Ingress

### Ingress Controllers Populares
- NGINX Ingress Controller
- Traefik
- HAProxy
- AWS ALB Ingress Controller

### Características de Ingress
- Path-based routing (`/api` → service-api)
- Host-based routing (`api.example.com` → service-api)
- TLS/SSL termination
- Load balancing

## ⚠️ Antes de Comenzar

```bash
# Habilitar Ingress addon en Minikube
minikube addons enable ingress

# Verificar Ingress Controller
kubectl get pods -n ingress-nginx

# Verificar cluster
kubectl cluster-info
```

## 🧹 Limpieza

```bash
cd lab-XX-nombre
./cleanup.sh
```

## 💡 Tips

- Usa `/etc/hosts` para pruebas locales
- Verifica logs del Ingress Controller si hay problemas
- TLS requiere certificados válidos en producción
