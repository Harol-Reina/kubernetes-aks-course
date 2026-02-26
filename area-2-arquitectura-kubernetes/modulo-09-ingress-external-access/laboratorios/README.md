# Laboratorios - Ingress y Acceso Externo

Este modulo contiene laboratorios practicos para dominar Ingress y acceso externo en Kubernetes.

## Indice de Laboratorios

### [Lab 01: Ingress Basico](./lab-01-ingress-basico/)
**Duracion:** 40-45 minutos | **Dificultad:** Basico

Introduccion a Ingress: instalacion del controller, apps de prueba, y enrutamiento por path y por host.

**Archivos YAML:**
- `deployment-apps-test.yaml` - Deployments y Services de prueba (app1, app2)
- `ingress-path-based.yaml` - Enrutamiento por path (/app1, /app2)
- `ingress-host-based.yaml` - Enrutamiento por host (app1.example.com)

---

### [Lab 02: Ingress TLS Avanzado](./lab-02-ingress-tls-avanzado/)
**Duracion:** 50-60 minutos | **Dificultad:** Intermedio

Configuracion de HTTPS, certificados wildcard, URL rewriting con regex, y CORS.

**Archivos YAML:**
- `ingress-tls-single.yaml` - TLS para un solo host con redireccion HTTP->HTTPS
- `ingress-multi-host-tls.yaml` - Multi-host con certificado wildcard
- `ingress-rewrite.yaml` - URL rewriting con expresiones regulares
- `ingress-cors.yaml` - CORS para peticiones cross-origin

---

### [Lab 03: Ingress en Produccion](./lab-03-ingress-produccion/)
**Duracion:** 60-70 minutos | **Dificultad:** Avanzado

Best practices de produccion: canary deployments, rate limiting, IP whitelist, alta disponibilidad y monitoreo.

**Archivos YAML:**
- `deployment-canary.yaml` - Deployments v1 (estable) y v2 (canary)
- `ingress-production.yaml` - Ingress principal (100% trafico a v1)
- `ingress-canary.yaml` - Ingress canary (20% trafico a v2)
- `ingress-rate-limit.yaml` - Rate limiting (5 rps, 10 conexiones)
- `ingress-whitelist.yaml` - Restriccion de acceso por IP
- `pdb-ingress-nginx.yaml` - PodDisruptionBudget para el controller

---

### [Lab Resumen: Todos los Patrones de Ingress](./lab-resumen-ingress/)
**Duracion:** 60 minutos | **Dificultad:** Repaso integral | **Plataforma:** Minikube

Un solo YAML despliega 4 backends + 6 Ingress resources para practicar todos los patrones de enrutamiento de un vistazo.

**Archivo YAML:**
- `ingress-lab.yaml` - Todo el lab en un archivo: namespace, deployments, services, ingress, pod de prueba

**Patrones cubiertos:**
Path-based routing, Host-based routing, Canary deployment, Rate limiting, URL rewriting, TLS termination

---

## Ruta de Aprendizaje Recomendada

1. **Nivel Basico** -> Lab 01 (Ingress basico)
2. **Nivel Intermedio** -> Lab 02 (TLS avanzado)
3. **Nivel Avanzado** -> Lab 03 (Produccion)
4. **Repaso integral** -> Lab Resumen (todos los patrones en 1 hora con Minikube)

**Tiempo total estimado:** 3.5-4.5 horas

## Enfoque Declarativo

Todos los laboratorios usan archivos YAML documentados en lugar de YAML inline. Cada archivo incluye:
- Descripcion del recurso y su proposito
- Conceptos clave explicados en los comentarios
- Prerequisitos y comandos de verificacion
- Namespace donde se crea el recurso

## Antes de Comenzar

```bash
# Verificar cluster
kubectl cluster-info

# Verificar archivos YAML disponibles en cada lab
ls lab-01-ingress-basico/*.yaml
ls lab-02-ingress-tls-avanzado/*.yaml
ls lab-03-ingress-produccion/*.yaml
```

## Limpieza

Cada laboratorio incluye un script `cleanup.sh` con limpieza especifica:

```bash
cd lab-XX-nombre
chmod +x cleanup.sh
./cleanup.sh
```
