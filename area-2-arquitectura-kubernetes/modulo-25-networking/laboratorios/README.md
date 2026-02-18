# Laboratorios - Módulo 25: Networking

## 📚 Descripción General

Esta carpeta contiene **4 laboratorios hands-on** progresivos que cubren todos los aspectos críticos de networking en Kubernetes, con enfoque especial en preparación para el examen **CKA (Certified Kubernetes Administrator)**.

## 🎯 Objetivos de los Laboratorios

- **Práctica intensiva** de conceptos de networking
- **Troubleshooting** sistemático de problemas reales
- **Preparación CKA**: ~20% del examen es networking
- **Experiencia real** con herramientas de debugging

---

## 📋 Listado de Laboratorios

### Lab 01: Services y DNS ⭐⭐
- **Archivo**: `lab-01-services-dns.md`
- **Duración**: 45-60 minutos
- **Dificultad**: Intermedio
- **CKA Coverage**: Services (10%), DNS (5%)

**Contenido:**
- ClusterIP Service (comunicación interna)
- NodePort Service (acceso externo)
- Headless Service (acceso directo a pods)
- DNS resolution (formatos y troubleshooting)
- Session Affinity (sticky sessions)
- Service troubleshooting (endpoints, labels, ports)

**Aprenderás a:**
- Crear y configurar todos los tipos de Services
- Entender y usar DNS en Kubernetes
- Diagnosticar problemas comunes de Services
- Trabajar con Endpoints y su relación con Pods

---

### Lab 02: Network Policies ⭐⭐⭐
- **Archivo**: `lab-02-network-policies.md`
- **Duración**: 60-75 minutos
- **Dificultad**: Avanzado
- **CKA Coverage**: Network Policies (5-10%)

**Contenido:**
- Default deny policies (ingress y egress)
- Three-tier application isolation
- podSelector, namespaceSelector, ipBlock
- DNS access policies
- Cross-namespace communication
- Troubleshooting de policies

**Aprenderás a:**
- Implementar modelo whitelist de seguridad
- Configurar aislamiento de red multi-tier
- Permitir DNS manteniendo seguridad
- Diagnosticar problemas de conectividad por policies

---

### Lab 03: Ingress Controllers ⭐⭐⭐
- **Archivo**: `lab-03-ingress.md`
- **Duración**: 60-75 minutos
- **Dificultad**: Avanzado
- **CKA Coverage**: Ingress (5-10%)

**Contenido:**
- Instalación de ingress-nginx controller
- Path-based routing
- Host-based routing (virtual hosts)
- TLS/HTTPS termination
- URL rewriting
- CORS configuration
- Rate limiting
- Custom security headers

**Aprenderás a:**
- Instalar y configurar Ingress Controllers
- Implementar routing complejo
- Configurar TLS con certificados
- Usar annotations avanzadas
- Troubleshoot problemas de Ingress

---

### Lab 04: Network Troubleshooting ⭐⭐⭐⭐
- **Archivo**: `lab-04-troubleshooting.md`
- **Duración**: 75-90 minutos
- **Dificultad**: Experto (Nivel CKA)
- **CKA Coverage**: Troubleshooting (15-20%)

**Contenido:**
- Metodología sistemática layer-by-layer
- Pod connectivity issues
- Service sin endpoints
- DNS resolution problems
- Pods not ready
- Ingress 404 errors
- Port mismatch
- Network performance debugging
- Challenge multi-problema

**Aprenderás a:**
- Diagnosticar problemas de red sistemáticamente
- Usar herramientas avanzadas (netshoot, tcpdump)
- Resolver múltiples problemas simultáneos
- Aplicar troubleshooting bajo presión (preparación examen)

---

## 🚀 Ruta de Aprendizaje Recomendada

```
Lab 01 (Services & DNS)
    ↓
    Fundamentos de conectividad
    ↓
Lab 02 (Network Policies)
    ↓
    Seguridad de red
    ↓
Lab 03 (Ingress)
    ↓
    Acceso externo
    ↓
Lab 04 (Troubleshooting)
    ↓
    Dominio completo
```

**Recomendación:** Completar en orden secuencial para máximo aprovechamiento.

---

## 📊 Matriz de Cobertura CKA

| Tema | Lab 01 | Lab 02 | Lab 03 | Lab 04 | % Examen |
|------|--------|--------|--------|--------|----------|
| Services | ✅✅✅ | ✅ | ✅ | ✅✅✅ | 10% |
| DNS | ✅✅✅ | ✅ | - | ✅✅ | 5% |
| Network Policies | - | ✅✅✅ | - | ✅✅ | 5-10% |
| Ingress | - | - | ✅✅✅ | ✅✅ | 5-10% |
| Troubleshooting | ✅ | ✅ | ✅ | ✅✅✅ | 15-20% |
| **TOTAL** | **15%** | **15%** | **15%** | **35%** | **40-55%** |

**⚠️ Importante:** Networking es ~20% del examen CKA. Estos labs cubren el 100% de ese 20% + troubleshooting adicional.

---

## 🛠️ Prerequisitos Generales

### Cluster de Kubernetes
- **Minikube**: Recomendado para labs locales
- **Kind**: Alternativa ligera
- **Cluster real**: AWS EKS, Azure AKS, GCP GKE, o bare-metal

### Instalación Minikube (Recomendado)

```bash
# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Iniciar con Calico (para Network Policies)
minikube start --cni=calico --cpus=2 --memory=4096

# Verificar
kubectl get nodes
kubectl get pods -n kube-system
```

### Herramientas Necesarias

```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl

# Verificar versiones
kubectl version --client
minikube version
```

### CNI con Soporte Network Policies

**Requerido para Lab 02:**
- ✅ Calico (recomendado)
- ✅ Cilium
- ✅ Weave Net
- ❌ Flannel (NO soporta Network Policies)

**Verificar CNI actual:**

```bash
kubectl get pods -n kube-system | grep -E "calico|cilium|weave"
```

---

## 📝 Estructura de Cada Laboratorio

Todos los laboratorios siguen la misma estructura:

1. **Metadata**: Duración, dificultad, objetivos CKA
2. **Objetivos de Aprendizaje**: Qué aprenderás
3. **Prerequisitos**: Requerimientos específicos
4. **Preparación**: Setup del entorno
5. **Ejercicios**: 6-10 ejercicios progresivos hands-on
6. **Troubleshooting**: Escenarios de problemas reales
7. **Verificación Final**: Checklist y validación
8. **Limpieza**: Cleanup del entorno
9. **Recursos**: Documentación y referencias

---

## 🎯 Tips para Máximo Aprovechamiento

### Antes de Empezar

1. ✅ Lee el README completo del módulo
2. ✅ Revisa el RESUMEN-MODULO.md (cheatsheet)
3. ✅ Verifica que tu cluster funciona correctamente
4. ✅ Ten a mano la documentación oficial de Kubernetes

### Durante el Laboratorio

1. **No copies y pegues ciegamente**: Entiende cada comando
2. **Experimenta**: Cambia valores, rompe cosas, aprende
3. **Anota errores**: Son oportunidades de aprendizaje
4. **Usa `kubectl explain`**: Para entender recursos
5. **Responde las preguntas**: Están marcadas con ❓

### Después del Laboratorio

1. **Revisa el RESUMEN**: Consolida conceptos clave
2. **Repite escenarios de troubleshooting**: Práctica la velocidad
3. **Crea tus propios escenarios**: Inventa problemas
4. **Cronométrate**: Para preparación de examen CKA

---

## 🔧 Comandos Útiles para Todos los Labs

### Setup Rápido

```bash
# Ver cluster info
kubectl cluster-info
kubectl get nodes -o wide

# Ver todos los recursos en un namespace
kubectl get all -n <namespace>

# Ver eventos
kubectl get events --sort-by='.lastTimestamp' -n <namespace>

# Limpiar namespace rápidamente
kubectl delete namespace <namespace>
```

### Debugging Esencial

```bash
# Pod de debugging con todas las herramientas
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- /bin/bash

# DNS test rápido
kubectl run test --rm -it --image=busybox:1.35 -- nslookup kubernetes

# HTTP test rápido
kubectl run test --rm -it --image=curlimages/curl -- curl http://service-name

# Port connectivity test
kubectl run test --rm -it --image=busybox:1.35 -- nc -zv service-name 80
```

### Troubleshooting Rápido

```bash
# Ver logs de CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50

# Ver logs de Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50

# Ver logs de CNI (Calico)
kubectl logs -n kube-system -l k8s-app=calico-node --tail=50

# Ver todas las network policies
kubectl get networkpolicies -A

# Ver todos los ingress
kubectl get ingress -A
```

---

## 📈 Tiempo Total Estimado

| Laboratorio | Tiempo Estimado | Tiempo con Troubleshooting | Tiempo Total Dedicación |
|-------------|-----------------|----------------------------|-------------------------|
| Lab 01 | 45-60 min | +15 min | ~75 min |
| Lab 02 | 60-75 min | +20 min | ~95 min |
| Lab 03 | 60-75 min | +20 min | ~95 min |
| Lab 04 | 75-90 min | +30 min | ~120 min |
| **TOTAL** | **4-5 horas** | **+1.5 horas** | **~6.5 horas** |

**Recomendación:** Distribuir en 2-3 sesiones de estudio.

---

## 🎓 Certificación y Preparación CKA

### Relevancia para CKA

Estos laboratorios cubren:
- **20% Networking** del examen CKA
- **15-20% Troubleshooting** del examen CKA
- **Total: ~35-40%** del contenido del examen

### Skills CKA que Practicarás

1. ✅ Entender arquitectura de networking de Kubernetes
2. ✅ Configurar Services (ClusterIP, NodePort, LoadBalancer)
3. ✅ Configurar Network Policies para aislamiento
4. ✅ Configurar Ingress para acceso HTTP/HTTPS
5. ✅ Troubleshoot problemas de red sistemáticamente
6. ✅ Usar herramientas de debugging (netshoot, tcpdump)
7. ✅ Diagnosticar problemas de DNS
8. ✅ Resolver problemas bajo presión de tiempo

### Tips Específicos para Examen

**Durante el Examen:**
- ⏱️ Tiempo limitado: Practica velocidad
- 📖 kubernetes.io permitido: Conoce dónde buscar
- 🚀 Comandos imperativos: Más rápido que YAML
- 🎯 Troubleshooting: Metodología sistemática layer-by-layer

**Comandos Imperativos Clave:**

```bash
# Crear service rápidamente
kubectl expose deployment <name> --port=80 --target-port=8080

# Crear ingress (usa kubectl create y edita)
kubectl create ingress <name> --rule="host/path=service:port"

# Ver YAML de ejemplo sin crear
kubectl create service clusterip myservice --tcp=80:8080 --dry-run=client -o yaml
```

---

## 🐛 Troubleshooting de los Labs

### Problema: Minikube no Inicia

```bash
# Borrar cluster anterior
minikube delete

# Reiniciar con recursos suficientes
minikube start --cni=calico --cpus=2 --memory=4096
```

### Problema: Network Policies no Funcionan

```bash
# Verificar CNI soporta Network Policies
kubectl get pods -n kube-system | grep -E "calico|cilium|weave"

# Si usas Flannel, reinicia con Calico
minikube delete
minikube start --cni=calico
```

### Problema: Ingress Controller no Funciona

```bash
# Para minikube
minikube addons enable ingress

# Verificar
kubectl get pods -n ingress-nginx
```

### Problema: CoreDNS no Resuelve

```bash
# Verificar CoreDNS running
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Ver logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Restart si es necesario
kubectl rollout restart deployment coredns -n kube-system
```

---

## 📚 Recursos Complementarios

### Documentación Oficial Kubernetes

- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [DNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

### Herramientas Útiles

- [netshoot](https://github.com/nicolaka/netshoot) - Swiss Army Knife para debugging
- [kube-network-policies](https://github.com/ahmetb/kubernetes-network-policy-recipes) - Recipes de Network Policies
- [Network Policy Editor](https://editor.cilium.io/) - Visual editor

### Cursos y Práctica

- [Killer.sh](https://killer.sh/) - Simulador examen CKA
- [KodeKloud](https://kodekloud.com/) - Labs CKA
- [A Cloud Guru](https://acloudguru.com/) - Curso CKA completo

---

## ✅ Checklist de Completion

Marca cuando completes cada laboratorio:

- [ ] **Lab 01**: Services y DNS completado
  - [ ] Ejercicio 1: ClusterIP Service
  - [ ] Ejercicio 2: NodePort Service
  - [ ] Ejercicio 3: Headless Service
  - [ ] Ejercicio 4: DNS Deep Dive
  - [ ] Ejercicio 5: Troubleshooting Services
  - [ ] Ejercicio 6: Session Affinity

- [ ] **Lab 02**: Network Policies completado
  - [ ] Ejercicio 1: Default Deny
  - [ ] Ejercicio 2: Three-Tier Isolation
  - [ ] Ejercicio 3: Egress Policies
  - [ ] Ejercicio 4: Namespace Isolation
  - [ ] Ejercicio 5: IP Block
  - [ ] Ejercicio 6: Troubleshooting
  - [ ] Ejercicio 7: Combined Policies

- [ ] **Lab 03**: Ingress completado
  - [ ] Ejercicio 1: Instalar Controller
  - [ ] Ejercicio 2: Path-based Routing
  - [ ] Ejercicio 3: Host-based Routing
  - [ ] Ejercicio 4: TLS/HTTPS
  - [ ] Ejercicio 5: URL Rewriting
  - [ ] Ejercicio 6: CORS
  - [ ] Ejercicio 7: Rate Limiting
  - [ ] Ejercicio 8: Security Headers
  - [ ] Ejercicio 9: Aplicación Completa
  - [ ] Ejercicio 10: Troubleshooting

- [ ] **Lab 04**: Troubleshooting completado
  - [ ] Escenario 1: Pod Connectivity
  - [ ] Escenario 2: Service No Endpoints
  - [ ] Escenario 3: DNS Failing
  - [ ] Escenario 4: Pods Not Ready
  - [ ] Escenario 5: Ingress 404
  - [ ] Escenario 6: Port Mismatch
  - [ ] Escenario 7: Performance
  - [ ] Escenario 8: Challenge Multi-problema

- [ ] **Bonus**: Crear tus propios escenarios de troubleshooting
- [ ] **Bonus**: Cronometrarte en labs para preparación CKA

---

## 🎉 ¡Éxito!

Al completar estos 4 laboratorios habrás:

✅ Dominado networking en Kubernetes  
✅ Practicado troubleshooting sistemático  
✅ Cubierto 35-40% del contenido del examen CKA  
✅ Ganado experiencia práctica con problemas reales  
✅ Preparado para el examen CKA en networking  

**Next Steps:**
1. Revisar RESUMEN-MODULO.md para consolidar
2. Practicar con cronómetro (preparación CKA)
3. Avanzar al Módulo 26: Advanced Troubleshooting

---

**¿Preguntas o problemas?** Revisa la sección de Troubleshooting o consulta la documentación oficial de Kubernetes.

**¡Mucho éxito en tu aprendizaje! 🚀**
