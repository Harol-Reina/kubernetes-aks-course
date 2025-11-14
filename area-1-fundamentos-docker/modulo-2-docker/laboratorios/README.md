# Laboratorios - Módulo 2: Docker Fundamentals

> **Objetivo**: Dominar Docker desde instalación hasta aplicaciones multi-contenedor  
> **Tiempo total estimado**: 8-10 horas  
> **Nivel**: Principiante a Intermedio

## 📁 Estructura

```
laboratorios/
├── README.md                          # Este archivo
├── lab-01-docker-install/             # Instalación de Docker
├── lab-02-comandos-basicos/           # Comandos esenciales
├── lab-03-primer-contenedor/          # Tu primer contenedor
├── lab-04-imagenes-personalizadas/    # Crear imágenes con Dockerfile
├── lab-05-volumenes-persistencia/     # Volúmenes y datos persistentes
├── lab-06-redes-docker/               # Networking en Docker
├── lab-07-namespaces-isolation/       # Namespaces y aislamiento
├── lab-08-docker-compose/             # Docker Compose
└── lab-09-ejercicios-practicos/       # Ejercicios integrados
```

## 📋 Laboratorios Disponibles

### Fundamentos (Labs 01-03)

**[Lab 01: Docker Install](./lab-01-docker-install/)** ⭐
- Instalar Docker en tu sistema
- Configurar permisos y grupos
- Verificar instalación correcta
- **Duración**: 30-45 min

**[Lab 02: Comandos Básicos](./lab-02-comandos-basicos/)** ⭐⭐
- Comandos esenciales de Docker
- docker run, ps, images, pull, push
- Gestión de contenedores e imágenes
- **Duración**: 45-60 min

**[Lab 03: Primer Contenedor](./lab-03-primer-contenedor/)** ⭐⭐
- Correr tu primer contenedor
- Modos interactivo y detached
- Port mapping y acceso
- **Duración**: 45-60 min

### Intermedio (Labs 04-06)

**[Lab 04: Imágenes Personalizadas](./lab-04-imagenes-personalizadas/)** ⭐⭐⭐
- Crear Dockerfile
- Build de imágenes custom
- Multi-stage builds
- Best practices
- **Duración**: 60-90 min

**[Lab 05: Volúmenes y Persistencia](./lab-05-volumenes-persistencia/)** ⭐⭐⭐
- Named volumes
- Bind mounts
- Persistencia de datos
- Backup y restore
- **Duración**: 60-75 min

**[Lab 06: Redes Docker](./lab-06-redes-docker/)** ⭐⭐⭐
- Tipos de redes (bridge, host, overlay)
- Comunicación entre contenedores
- DNS interno
- Port publishing
- **Duración**: 75-90 min

### Avanzado (Labs 07-09)

**[Lab 07: Namespaces e Isolation](./lab-07-namespaces-isolation/)** ⭐⭐⭐⭐
- Namespaces de Linux
- PID, network, mount namespaces
- Aislamiento de procesos
- Seguridad en contenedores
- **Duración**: 75-90 min

**[Lab 08: Docker Compose](./lab-08-docker-compose/)** ⭐⭐⭐⭐
- Definir aplicaciones multi-contenedor
- docker-compose.yml
- Networks y volumes en Compose
- Escalado de servicios
- **Duración**: 90-120 min

**[Lab 09: Ejercicios Prácticos](./lab-09-ejercicios-practicos/)** ⭐⭐⭐⭐
- Ejercicios integrados
- Debugging challenges
- Troubleshooting real
- Proyectos completos
- **Duración**: 120-180 min

---

## 🚀 Ruta de Aprendizaje Recomendada

### Semana 1: Fundamentos
```bash
Día 1: Lab 01 (Instalación)
Día 2: Lab 02 (Comandos básicos)
Día 3: Lab 03 (Primer contenedor)
Día 4-5: Práctica y experimentación
```

### Semana 2: Intermedio
```bash
Día 1-2: Lab 04 (Imágenes personalizadas)
Día 3: Lab 05 (Volúmenes)
Día 4-5: Lab 06 (Redes)
```

### Semana 3: Avanzado
```bash
Día 1-2: Lab 07 (Namespaces)
Día 3-4: Lab 08 (Docker Compose)
Día 5: Lab 09 (Ejercicios)
```

## 📊 Progresión de Dificultad

```
Lab 01 ⭐            Instalación
Lab 02 ⭐⭐          Comandos
Lab 03 ⭐⭐          Primer contenedor
Lab 04 ⭐⭐⭐        Dockerfile
Lab 05 ⭐⭐⭐        Volúmenes
Lab 06 ⭐⭐⭐        Redes
Lab 07 ⭐⭐⭐⭐      Namespaces
Lab 08 ⭐⭐⭐⭐      Compose
Lab 09 ⭐⭐⭐⭐      Ejercicios
```

## 🎯 Resultados de Aprendizaje

Al completar todos los laboratorios, serás capaz de:

**Operaciones Básicas**:
- [ ] Instalar y configurar Docker
- [ ] Ejecutar comandos Docker esenciales
- [ ] Correr y gestionar contenedores
- [ ] Trabajar con imágenes de Docker Hub

**Creación de Imágenes**:
- [ ] Escribir Dockerfiles efectivos
- [ ] Build de imágenes personalizadas
- [ ] Optimizar tamaño de imágenes
- [ ] Usar multi-stage builds

**Datos y Networking**:
- [ ] Gestionar volúmenes para persistencia
- [ ] Configurar redes entre contenedores
- [ ] Exponer servicios con port mapping
- [ ] Compartir datos entre contenedores

**Aplicaciones Multi-contenedor**:
- [ ] Escribir docker-compose.yml
- [ ] Orquestar múltiples servicios
- [ ] Escalar aplicaciones
- [ ] Debugging y troubleshooting

## 💡 Tips para el Éxito

### Antes de Empezar
- Completa labs en orden secuencial
- No saltes fundamentos (Labs 1-3)
- Ten un editor de texto listo
- Documenta comandos que uses

### Durante los Labs
- Experimenta más allá de las instrucciones
- Rompe cosas intencionalmente (aprenderás más)
- Toma notas de errores comunes
- Usa `docker --help` cuando tengas dudas

### Después de Cada Lab
- Ejecuta cleanup.sh
- Revisa conceptos que no quedaron claros
- Practica comandos sin mirar apuntes
- Construye algo propio usando lo aprendido

## 🔧 Troubleshooting General

### Docker daemon not running
```bash
# Linux
sudo systemctl start docker
sudo systemctl status docker

# macOS/Windows
# Iniciar Docker Desktop
```

### Permission denied
```bash
# Linux - agregar usuario al grupo docker
sudo usermod -aG docker $USER
# Logout y login para aplicar
```

### Port already in use
```bash
# Ver qué usa el puerto
sudo lsof -i :8080
# O usar otro puerto
docker run -p 8081:80 nginx
```

### Out of disk space
```bash
# Limpiar recursos
docker system prune -a
docker volume prune
```

## 📚 Recursos Adicionales

- **Docs Oficiales**: [docs.docker.com](https://docs.docker.com)
- **Docker Hub**: [hub.docker.com](https://hub.docker.com)
- **Play with Docker**: [labs.play-with-docker.com](https://labs.play-with-docker.com)
- **Cheat Sheet**: [docker.com/cheatsheet](https://www.docker.com/cheatsheet)

## ✅ Checklist de Completitud

- [ ] **Lab 01**: Docker instalado y funcionando
- [ ] **Lab 02**: Comandos básicos dominados
- [ ] **Lab 03**: Primer contenedor corriendo
- [ ] **Lab 04**: Primera imagen custom creada
- [ ] **Lab 05**: Datos persistiendo con volúmenes
- [ ] **Lab 06**: Contenedores comunicándose
- [ ] **Lab 07**: Namespaces comprendidos
- [ ] **Lab 08**: App multi-contenedor con Compose
- [ ] **Lab 09**: Ejercicios completados

## 🎓 Certificación y Siguiente Nivel

Después de dominar estos labs:
1. Practica construyendo proyectos propios
2. Explora Docker Swarm (orquestación básica)
3. **¡Siguiente área!**: Kubernetes (orquestación avanzada)
4. Considera certificación Docker (DCA)

---

**¡Feliz containerización! 🐳**

[Volver al módulo](../README.md)
