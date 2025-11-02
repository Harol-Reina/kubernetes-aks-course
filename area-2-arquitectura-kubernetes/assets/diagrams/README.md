# 🎨 **Diagramas Draw.io para Curso Kubernetes**

## 📁 **Estructura de Diagramas:**

```
assets/diagrams/
├── 01-introduccion/
│   ├── docker-vs-kubernetes.drawio
│   ├── traditional-vs-k8s-resources.drawio
│   ├── kubernetes-abstraction.drawio
│   └── roles-separation.drawio
├── 02-arquitectura/
│   ├── cluster-overview.drawio
│   ├── control-plane-detail.drawio
│   ├── worker-node-detail.drawio
│   └── component-communication.drawio
├── 03-networking/
│   ├── service-discovery.drawio
│   ├── ingress-flow.drawio
│   └── pod-to-pod-communication.drawio
└── templates/
    ├── kubernetes-icons.drawio
    └── base-template.drawio
```

---

## 🚀 **Métodos de Integración:**

### **Opción 1: Draw.io Embebido en GitHub** ⭐ **RECOMENDADO**
```markdown
<!-- Sintaxis para embeber draw.io en GitHub -->
![Kubernetes Architecture](./assets/diagrams/cluster-overview.drawio.svg)
```

### **Opción 2: Exportar como SVG/PNG**
```markdown
![Kubernetes Architecture](./assets/diagrams/cluster-overview.svg)
```

### **Opción 3: Draw.io Viewer Online**
```markdown
[📊 Ver Diagrama Interactivo](https://viewer.diagrams.net/?url=https://raw.githubusercontent.com/your-repo/assets/diagrams/cluster-overview.drawio)
```

---

## 🛠️ **Instrucciones de Uso:**

### **Para Crear Nuevos Diagramas:**

1. **🌐 Abre Draw.io:**
   - Visita: https://app.diagrams.net/
   - O usa VS Code con extensión Draw.io Integration

2. **📂 Carga Template Base:**
   ```
   File → Open → Selecciona template/base-template.drawio
   ```

3. **🎨 Usa Iconos Kubernetes:**
   - Carga: `templates/kubernetes-icons.drawio`
   - Copia los iconos necesarios

4. **💾 Guarda en formato correcto:**
   ```
   File → Export as → SVG (para GitHub)
   File → Save as → .drawio (para edición futura)
   ```

### **Para Editar Diagramas Existentes:**

1. **🔄 Abre archivo .drawio:**
   ```
   https://app.diagrams.net/ → Open Existing Diagram
   ```

2. **✏️ Edita y exporta:**
   ```
   Editar → Export as SVG → Reemplazar archivo anterior
   ```

---

## 🎯 **Diagramas Prioritarios por Módulo:**

### **Módulo 01 - Introducción:**
- [x] **docker-vs-kubernetes.drawio** - Comparación evolutiva
- [x] **traditional-vs-k8s-resources.drawio** - Eficiencia de recursos
- [x] **kubernetes-abstraction.drawio** - Capa de abstracción
- [x] **roles-separation.drawio** - Desarrolladores vs Admins vs K8s

### **Templates Base:**
- [x] **base-template.drawio** - ✨ **MEJORADO** - Arquitectura completa K8s
  - ✅ Control Plane completo (5 componentes)
  - ✅ Worker Nodes detallados (kubelet, kube-proxy, containerd, CNI)
  - ✅ 15+ Pods distribuidos por nodos
  - ✅ External Access (Load Balancer, Ingress, Internet)
  - ✅ Conexiones completas entre componentes
  - ✅ Diseño enterprise-level

### **Módulo 02 - Arquitectura:** 🆕 **PRÓXIMO**
- [ ] **cluster-overview.drawio** - Vista general del cluster
- [ ] **control-plane-detail.drawio** - Componentes control plane
- [ ] **worker-node-detail.drawio** - Anatomía worker node
- [ ] **component-communication.drawio** - Flujo de comunicación

### **Módulo 08 - Networking:**
- [ ] **service-discovery.drawio** - Descubrimiento de servicios
- [ ] **ingress-flow.drawio** - Flujo de tráfico externo
- [ ] **pod-to-pod-communication.drawio** - Comunicación interna

---

## 🎨 **Estándares de Diseño:**

### **Colores Estándar:**
```
🟦 Control Plane:    #1976D2 (Azul)
🟩 Worker Nodes:     #388E3C (Verde)
🟨 Applications:     #F57C00 (Naranja)
🟪 External:         #7B1FA2 (Púrpura)
🟥 Problems/Alerts:  #D32F2F (Rojo)
⬜ Background:       #F5F5F5 (Gris claro)
```

### **Iconos Estándar:**
```
🖥️  Servidores/Nodos
🐳  Contenedores/Pods
⚙️  Configuración
🌐  Networking
💾  Storage
🛡️  Security
📊  Monitoring
🔄  Procesos
```

### **Tipografía:**
```
Títulos:     14px, Bold, Roboto
Subtítulos:  12px, Medium, Roboto
Texto:       10px, Regular, Roboto
Labels:      8px, Regular, Roboto
```

---

## 📋 **Lista de Tareas:**

### **✅ Completado:**
- [x] Estructura de carpetas creada
- [x] Templates base definidos y mejorados
- [x] Estándares de diseño establecidos
- [x] **🚀 Template base-template.drawio completamente renovado**
  - [x] Arquitectura Kubernetes completa (Control Plane + Workers)
  - [x] Todos los componentes principales incluidos
  - [x] Diseño enterprise-level profesional
  - [x] 15+ pods distribuidos realísticamente

### **🔄 En Progreso:**
- [ ] Crear template base con iconos K8s
- [ ] Generar diagramas Módulo 01
- [ ] Implementar integración GitHub

### **📅 Pendiente:**
- [ ] Diagramas Módulo 02-20
- [ ] Automatización de exports
- [ ] Documentación de mantenimiento

---

## 🔗 **Enlaces Útiles:**

- **[🎨 Draw.io Official](https://app.diagrams.net/)**
- **[📚 Draw.io Documentation](https://desk.draw.io/support/home)**
- **[🐙 GitHub Draw.io Integration](https://github.com/jgraph/drawio-github)**
- **[🔧 VS Code Draw.io Extension](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio)**
- **[🎯 Kubernetes Icons Pack](https://github.com/kubernetes/community/tree/master/icons)**

---

**💡 Nota**: Los archivos .drawio son compatibles con GitHub y se pueden ver/editar directamente en el navegador.