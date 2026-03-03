# 📚 RESUMEN - Módulo 03 (Área 3): Network Policies

**Guía de Estudio Rápido y Referencia de Comandos**

---

## 🎯 Visión General del Módulo

Este módulo cubre las **Network Policies** en Kubernetes — el mecanismo para controlar el tráfico de red entre Pods. Aprenderás a implementar firewalls a nivel de Pod, aislar namespaces, y diseñar políticas que sigan el principio de mínimo privilegio a nivel de red.

**Duración**: 6 horas (teoría + labs)
**Nivel**: Intermedio-Avanzado
**Prerequisitos**: Pods, Services, Namespaces, conceptos básicos de networking (IP, puertos, TCP/UDP)

---

## 📋 Objetivos de Aprendizaje

### Fundamentos
- ✅ Explicar qué es una NetworkPolicy y por qué es necesaria
- ✅ Diferenciar entre ingress y egress en el contexto de red
- ✅ Entender que sin policies todo el tráfico está permitido
- ✅ Conocer qué CNI soportan Network Policies (Calico, Azure CNI, Cilium)

### Técnico
- ✅ Crear NetworkPolicies de tipo deny-all
- ✅ Permitir tráfico selectivo por labels, namespaces y puertos
- ✅ Configurar reglas de egress para controlar tráfico saliente
- ✅ Aislar namespaces entre sí con policies
- ✅ Permitir tráfico DNS (necesario para resolución de nombres)

### Troubleshooting
- ✅ Diagnosticar conectividad bloqueada por policies
- ✅ Usar `kubectl exec` para probar conectividad
- ✅ Verificar que el CNI soporta Network Policies

---

## 🗺️ Estructura de Aprendizaje

### ¿Cómo Funciona una Network Policy?

```
SIN Network Policies:                CON Network Policies:
┌──────────────────────────┐         ┌──────────────────────────┐
│  Todos hablan con todos:  │         │  Solo tráfico autorizado: │
│                           │         │                           │
│  [Frontend] ←──→ [Backend]│         │  [Frontend] ──→ [Backend] │
│  [Frontend] ←──→ [DB]    │         │  [Frontend] ✗→ [DB]      │
│  [Backend]  ←──→ [DB]    │         │  [Backend]  ──→ [DB]     │
│  [Atacante] ←──→ [DB]    │         │  [Atacante] ✗→ [DB]      │
│                           │         │  [Atacante] ✗→ [Backend] │
└──────────────────────────┘         └──────────────────────────┘
```

### Diagrama de Ingress vs Egress

```
           Ingress (entrada)              Egress (salida)
           ┌──────────┐                  ┌──────────┐
  ──────►  │   POD    │                  │   POD    │  ──────►
  Quién    │          │                  │          │  A dónde
  puede    │  (destino)│                  │  (origen) │  puede
  ENTRAR   └──────────┘                  └──────────┘  SALIR
```

### Tipos de Selectores

| Selector | Qué selecciona | Ejemplo |
|----------|---------------|---------|
| `podSelector` | Pods por labels | `app: backend` |
| `namespaceSelector` | Namespaces por labels | `env: production` |
| `ipBlock` | Rangos de IP | `192.168.0.0/16` |

---

## 🔧 Comandos Esenciales

### Básicos

```bash
# Ver Network Policies
kubectl get networkpolicies -n <namespace>
kubectl get netpol -n <namespace>    # forma corta

# Ver detalles de una policy
kubectl describe netpol <name> -n <namespace>

# Probar conectividad entre Pods
kubectl exec <pod-origen> -n <ns> -- wget -qO- --timeout=3 http://<servicio>
kubectl exec <pod-origen> -n <ns> -- nc -zv <ip> <puerto> -w 3
```

### Crear Policies

```bash
# Deny-all ingress
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: mi-namespace
spec:
  podSelector: {}      # Aplica a TODOS los Pods
  policyTypes:
  - Ingress             # Bloquea todo tráfico de entrada
EOF
```

---

## 📝 Cheat Sheet: YAML Snippets

### Deny All (Bloquear Todo)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}        # Aplica a todos los Pods del namespace
  policyTypes:
  - Ingress
  - Egress
```

### Permitir Tráfico Específico

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app: backend       # Se aplica a Pods con label app=backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend  # Solo permite tráfico desde Pods con app=frontend
    ports:
    - port: 8080
      protocol: TCP
```

### Permitir DNS (Siempre Necesario)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}    # Cualquier namespace
    ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
```

### Aislamiento de Namespace

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: mi-namespace   # Solo permite tráfico del mismo namespace
```

---

## ❗ Problemas Comunes y Soluciones

### 1. Network Policy no bloquea tráfico

**Causa**: El CNI no soporta Network Policies (ej: flannel básico).
**Verificación**: `kubectl get pods -n kube-system | grep calico`
**Solución**: Usar Calico, Cilium, o Azure CNI con policy habilitado.

### 2. Pods no pueden resolver DNS después de deny-all

**Causa**: Se bloqueó egress al DNS (CoreDNS en puerto 53).
**Solución**: Crear una policy que permita egress al puerto 53 UDP/TCP.

### 3. Tráfico permitido pero conexión falla

**Causa**: La policy permite ingress pero no egress del Pod origen.
**Solución**: Verificar que tanto ingress del destino como egress del origen están permitidos.

### 4. Policy no se aplica a los Pods correctos

**Causa**: Los labels del `podSelector` no coinciden con los Pods.
**Diagnóstico**: `kubectl get pods --show-labels -n <ns>`

### 5. Tráfico entre namespaces bloqueado

**Causa**: Falta `namespaceSelector` en la policy.
**Solución**: Agregar `namespaceSelector` con labels del namespace origen.

---

## ✅ Checklist de Conceptos

- [ ] Entiendo que sin policies todo el tráfico está permitido
- [ ] Sé crear una policy deny-all (baseline seguro)
- [ ] Puedo permitir tráfico selectivo por labels
- [ ] Entiendo la diferencia entre ingress y egress
- [ ] Sé permitir tráfico DNS (puerto 53 UDP/TCP)
- [ ] Puedo aislar namespaces con policies
- [ ] Sé probar conectividad con `kubectl exec`
- [ ] Entiendo qué CNIs soportan Network Policies

---

## 📝 Preguntas de Repaso

### 1. ¿Qué pasa con el tráfico si no hay Network Policies?

<details><summary>Ver respuesta</summary>
Todo el tráfico está permitido por defecto. Cualquier Pod puede comunicarse con cualquier otro Pod en el cluster, incluso entre namespaces diferentes.
</details>

### 2. ¿Qué es una policy deny-all y por qué es importante?

<details><summary>Ver respuesta</summary>
Una policy deny-all bloquea todo el tráfico de entrada (ingress) y/o salida (egress) a todos los Pods del namespace. Es la base de una estrategia "default deny": empiezas bloqueando todo y luego permites solo lo necesario.
</details>

### 3. ¿Por qué necesitas permitir DNS explícitamente?

<details><summary>Ver respuesta</summary>
Cuando bloqueas egress, también bloqueas las consultas DNS al CoreDNS (puerto 53). Sin DNS, los Pods no pueden resolver nombres de Service como `backend.mi-namespace.svc.cluster.local`, y todas las conexiones por nombre fallan.
</details>

### 4. ¿Cuál es la diferencia entre ingress y egress?

<details><summary>Ver respuesta</summary>
**Ingress** controla qué tráfico puede ENTRAR al Pod (quién puede conectarse a él). **Egress** controla qué tráfico puede SALIR del Pod (a dónde puede conectarse). Son independientes: puedes tener reglas de ingress sin egress y viceversa.
</details>

### 5. ¿Cómo verificas que una Network Policy está funcionando?

<details><summary>Ver respuesta</summary>

```bash
# Desde un Pod que DEBERÍA poder conectarse (debe funcionar)
kubectl exec frontend-pod -- wget -qO- --timeout=3 http://backend-service

# Desde un Pod que NO debería poder conectarse (debe fallar)
kubectl exec atacante-pod -- wget -qO- --timeout=3 http://backend-service
```
</details>

---

## 🎓 Relevancia para Certificaciones

### CKA
- Network Policies son ~8% del examen
- Crear policies de ingress y egress
- Aislar namespaces

### CKAD
- Configurar Network Policies para aplicaciones
- Entender cómo afectan la comunicación entre servicios

### AKS Specialty
- Azure CNI vs kubenet con Network Policies
- Azure Network Policy vs Calico en AKS
- Integración con Azure NSG (Network Security Groups)

---

## 🔗 Siguiente Paso

Continúa con el **Módulo 04: Almacenamiento Persistente** para aprender a mantener datos que sobrevivan al reinicio de Pods.
