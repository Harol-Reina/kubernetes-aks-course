# Sesion 1 — Guion del Instructor

> **Fecha**: 19 de febrero 2026 | **Horario**: 7:00 PM - 10:00 PM (3 horas)
> **Tema**: Area 1 - Modulo 1: Virtualizacion Tradicional
> **Material**: [Modulo 1 README.md](../../../area-1-fundamentos-docker/modulo-1-virtualizacion/README.md)

---

## BLOQUE 1: Apertura y Contexto (7:00 - 7:30) — 30 min

### 7:00 - 7:10 | Bienvenida y presentacion del curso

**Abrir**: [README.md principal](../README.md)

**Decir**:

> Bienvenidos al curso de Fundamentos de Kubernetes y su Implementacion en Azure AKS.
> Son 32 horas divididas en 4 areas. Al final del curso van a poder administrar clusters de Kubernetes en produccion.

**Mostrar la estructura del curso en pantalla**:

- Area 1: Fundamentos Docker (6h) — **donde estamos hoy**
- Area 2: Arquitectura Kubernetes (8h) — el core del curso
- Area 3: Operacion y Seguridad (9h) — produccion real
- Area 4: Observabilidad y HA (9h) — monitoreo, CI/CD

**Mencionar certificaciones objetivo**:

> Este curso les prepara para tres certificaciones:
> - CKAD (Certified Kubernetes Application Developer) — 85-90% cobertura
> - CKA (Certified Kubernetes Administrator) — 60-65% cobertura
> - Azure AKS Specialty — 70-75% cobertura

---

### 7:10 - 7:20 | Roadmap: La evolucion de la infraestructura

**Abrir**: [Area 1 README](../../../area-1-fundamentos-docker/README.md) — seccion "Ruta de Aprendizaje"

**Dibujar o mostrar en pantalla este diagrama** (esta en el README del Area 1):

```
  Servidores Fisicos        1 servidor = 1 aplicacion
         |                  Alto costo, desperdicio de recursos
         v
  Virtualizacion (hoy)      Multiples VMs por servidor
         |                  Mejor aprovechamiento de hardware
         v
  Contenedores (sesion 2-3)  100+ contenedores/servidor
         |                  Arranque instantaneo, portabilidad
         v
  Kubernetes (Area 2+)      Gestion de miles de contenedores
                            Auto-scaling, self-healing
```

**Decir**:

> Hoy vamos a entender el primer gran salto: de servidores dedicados a la virtualizacion.
> Esto es fundamental porque Kubernetes ejecuta contenedores DENTRO de VMs.
> Si no entienden virtualizacion, no van a entender por que Kubernetes hace lo que hace.

---

### 7:20 - 7:30 | Verificacion de prerrequisitos

**Abrir**: [Prerrequisitos M1](../../../area-1-fundamentos-docker/modulo-1-virtualizacion/README.md) — seccion "Prerrequisitos"

**Pedir a los alumnos que verifiquen**:

```bash
# Verificar cliente SSH
ssh -V
# Esperado: OpenSSH_X.X

# Verificar Azure CLI (si lo tienen)
az --version

# Verificar conectividad
ping portal.azure.com
```

**Confirmar**:
- Todos tienen cuenta de Azure activa?
- Todos pueden acceder a portal.azure.com?
- Quien tiene Azure CLI instalado? (no es obligatorio hoy, usaremos el Portal)

---

## BLOQUE 2: Teoria de Virtualizacion (7:30 - 8:40) — 70 min

### 7:30 - 7:50 | Seccion 1: Contexto historico (20 min)

**Abrir**: Modulo 1 README — Seccion 1 "Contexto historico"

**Punto clave — El problema**:

> Antes de la virtualizacion, cada aplicacion requeria un servidor fisico dedicado.
> Imaginen una empresa con 50 aplicaciones: necesitaba 50 servidores fisicos.

**Mostrar los 4 problemas**:

1. Alto costo de hardware — un servidor por aplicacion
2. Espacio fisico y consumo energetico enormes
3. Desperdicio de recursos — CPU y RAM al 10-30% de uso
4. Dificultad de escalamiento — comprar hardware nuevo toma semanas

**Mostrar diagrama ASCII del README** (seccion "Hardware vs. Virtual"):

```
SERVIDOR TRADICIONAL (Dedicado)
  App 1    |    DESPERDICIO DE RECURSOS
  SO 1     |    (70-80% CPU/RAM sin usar)
  Hardware |

         VIRTUALIZACION

SERVIDOR VIRTUALIZADO
  VM 1     VM 2     VM 3     VM 4
  App A    App B    App C    App D
  SO       SO       SO       SO
       HIPERVISOR
  Hardware Fisico Compartido (Uso 70-90%)
```

**Decir**:

> La virtualizacion fue la solucion: compartir un servidor fisico entre multiples sistemas operativos aislados.
> Ejemplo: un servidor con 64 GB RAM y 16 nucleos puede correr 4 VMs de 16 GB y 4 nucleos cada una.

---

### 7:50 - 8:10 | Secciones 2-3: Que es la virtualizacion + Arquitectura (20 min)

**Abrir**: Modulo 1 README — Secciones 2 y 3

**Definicion tecnica**:

> La virtualizacion permite crear distintos entornos virtuales simulados desde una sola maquina fisica.
> Una VM es un entorno informatico que funciona como sistema aislado con su propia CPU, SO, memoria, red y almacenamiento.

**Los 3 componentes principales** — escribir en pizarra o mostrar:

| Componente | Que es |
|-----------|--------|
| **Host** | Servidor fisico que provee CPU, RAM, disco, red |
| **Hipervisor** | Software que gestiona las VMs y distribuye recursos |
| **Guest (VM)** | Sistema operativo que corre dentro de la VM |

**Mostrar diagrama de arquitectura**:

```
  Aplicaciones (VM1, VM2...)
  Sistemas Operativos Guest
  Hipervisor (ESXi / KVM)
  Hardware Fisico (CPU, RAM)
```

**TEMA CLAVE — Tipos de hipervisores**:

> Esto es lo mas importante de esta seccion. Hay dos tipos:

| | Tipo 1 (Bare-metal) | Tipo 2 (Hosted) |
|---|---|---|
| **Donde corre** | Directo sobre hardware | Sobre un SO existente |
| **Rendimiento** | Mayor, menor latencia | Menor rendimiento |
| **Uso** | Servidores empresariales | Desarrollo, pruebas |
| **Ejemplos** | VMware ESXi, KVM, Hyper-V Server | VirtualBox, VMware Workstation |

**Pregunta interactiva**:

> Azure, AWS y Google Cloud... que tipo de hipervisor usan? (Tipo 1)
> Azure usa Hyper-V, AWS usa KVM/Nitro. Son bare-metal porque necesitan maximo rendimiento.

**Mencionar KVM especificamente**:

> KVM es importante para este curso: es open source, esta integrado en el kernel de Linux,
> y es el hipervisor que usan la mayoria de clouds publicos. Kubernetes corre sobre VMs
> que generalmente usan KVM por debajo.

---

### 8:10 - 8:30 | Seccion 4: Tipos de virtualizacion (20 min)

**Abrir**: Modulo 1 README — Seccion 4

**Mostrar los 6 tipos** (no profundizar en todos, enfocarse en los primeros 3):

| Tipo | Que virtualiza | Ejemplo |
|------|---------------|---------|
| **Servidores** | Particion de un servidor fisico en VMs | VMware ESXi, KVM, Hyper-V |
| **Escritorios (VDI)** | Entornos de escritorio remoto | Citrix, VMware Horizon |
| **Red** | Redes virtuales independientes del hardware | vSwitch, NSX |
| Almacenamiento | Discos fisicos en volumenes logicos | vSAN, LVM |
| Datos | Federacion de datos de multiples fuentes | Denodo |
| Aplicaciones | Apps fuera de su SO original | App-V, ThinApp |

**Enfocarse en la comparacion clave** — Mostrar la tabla del README:

> Lo que nos importa para este curso es entender la diferencia entre estas tres:

| Aspecto | Virt. Aplicaciones | VDI (Escritorios) | Contenedores |
|---------|-------|-------|-------|
| Que virtualiza | Solo la app | SO completo | App + dependencias |
| Tamanio | 100MB - 1GB | 20-50 GB | 50-500 MB |
| Arranque | Segundos | 1-5 minutos | 1-3 segundos |
| Uso tipico | Apps legacy | Trabajo remoto | DevOps, microservicios |

**Decir**:

> Noten como los contenedores toman lo mejor de cada mundo:
> el peso ligero de la virtualizacion de apps, pero con aislamiento completo.
> Esto es lo que vamos a explorar en Docker la proxima sesion.

---

### 8:30 - 8:40 | Seccion 5: Ventajas y desventajas (10 min)

**Abrir**: Modulo 1 README — Seccion 5

**Ventajas** (pedir que los alumnos las mencionen primero):

- Consolidacion de servidores (de 50 servidores a 5)
- Ahorro de costos (energia, espacio, hardware)
- Entornos aislados (una VM no afecta a otra)
- Migracion rapida (clonar, mover, crear en minutos)
- Recuperacion ante desastres (snapshots, backups)

**Desventajas** (estas son las que motivan la aparicion de contenedores):

- Cada VM necesita SO completo (2+ GB RAM solo para el SO)
- Arranque lento (minutos)
- Licencias costosas (Windows, RHEL en cada VM)
- Escalabilidad limitada (max 10-20 VMs por servidor)
- El hipervisor es un punto unico de falla

**Mostrar tabla comparativa**:

| Metrica | Fisico | Virtualizado | Contenedores |
|---------|--------|-------------|--------------|
| Densidad | 1 app/servidor | 3-10 apps/servidor | 100+ apps/servidor |
| Arranque | Minutos | Minutos | **Segundos** |
| Overhead SO | Ninguno | Alto | **Minimo** |

> Guarden esta tabla en la cabeza. Cuando veamos Docker, van a entender por que
> los contenedores resuelven estas limitaciones.

---

## BREAK (8:40 - 8:50) — 10 min

> Tomen un descanso. En 10 minutos vamos al laboratorio practico con Azure.

---

## BLOQUE 3: Laboratorio Azure VMs (8:50 - 9:35) — 45 min

**Abrir**: [Lab 01 Azure VM](../../../area-1-fundamentos-docker/modulo-1-virtualizacion/laboratorios/lab-01-azure-vm/README.md)

### 8:50 - 9:10 | Crear VM en Azure Portal (20 min)

**Hacer esto EN VIVO, paso a paso, pidiendo que los alumnos sigan junto contigo**.

**Paso 1**: Navegar a portal.azure.com

**Paso 2**: Buscar "Maquinas virtuales" > Crear > Maquina virtual de Azure

**Paso 3**: Configurar (ir campo por campo):

```
Suscripcion:          [la del alumno]
Grupo de recursos:    Crear nuevo > "rg-curso-k8s-lab1"
Nombre de la VM:      vm-virtualizacion-lab
Region:               East US (o la mas cercana)
Imagen:               Ubuntu Server 22.04 LTS - x64 Gen2
Tamanio:              Standard_B1s (1 vcpu, 1 GiB memory)
Autenticacion:        Clave publica SSH
Usuario:              azureuser
Par de claves:        vm-key-lab1
Puerto de entrada:    SSH (22)
```

**Decir mientras se crea**:

> Fijense que estamos eligiendo Standard_B1s: 1 vCPU y 1 GB RAM.
> Esto es lo minimo que Azure permite. Es una fraccion del servidor fisico real.
> Azure usa Hyper-V por debajo para crear esta VM, exactamente lo que vimos en la teoria.

**Paso 4**: Revisar y crear > Crear

**Paso 5**: **Importante** — Descargar la clave privada (.pem) cuando lo pida

> El despliegue tarda 2-5 minutos. Mientras esperamos, alguien me puede decir
> que tipo de hipervisor esta usando Azure? (Tipo 1 — Hyper-V bare-metal)

---

### 9:10 - 9:25 | Conectarse y explorar la VM (15 min)

**Una vez desplegada la VM**:

**Paso 1**: Obtener la IP publica desde el portal

**Paso 2**: Configurar permisos de la clave y conectarse:

```bash
# Dar permisos correctos a la clave
chmod 600 ~/Downloads/vm-key-lab1.pem

# Conectarse por SSH
ssh -i ~/Downloads/vm-key-lab1.pem azureuser@<IP_PUBLICA>
```

**Paso 3**: Ya dentro de la VM, ejecutar estos comandos UNO POR UNO explicando:

```bash
# Informacion del SO
cat /etc/os-release
# >> Explica: Ubuntu 22.04, es un SO completo corriendo dentro de la VM

# Cuantos CPUs tenemos?
lscpu
# >> Explica: 1 CPU virtual. El servidor real tiene 32-64 CPUs,
#    pero Azure nos asigno solo 1 via el hipervisor.

# Cuanta memoria?
free -h
# >> Explica: ~1 GB. Noten que parte ya esta usada por el SO.
#    Este es el "overhead" del que hablamos.

# Espacio en disco?
df -h
# >> Explica: Disco virtual, tambien asignado por el hipervisor

# Estamos realmente en una VM?
sudo dmidecode -s system-manufacturer
# >> Deberia mostrar "Microsoft Corporation"

lscpu | grep Hypervisor
# >> Deberia mostrar "Hypervisor vendor: Microsoft"
#    Confirmado: estamos corriendo sobre Hyper-V
```

**Momento de reflexion**:

> Acaban de ver la virtualizacion en accion. Este Ubuntu cree que tiene su propio hardware,
> pero en realidad comparte un servidor fisico con decenas de otras VMs de otros clientes de Azure.
> El hipervisor se encarga de que cada VM este aislada.

---

### 9:25 - 9:35 | Gestion del ciclo de vida (10 min)

**Desde el Portal de Azure**, mostrar:

1. **Detener la VM** — Click en "Detener"
   > Noten cuanto tarda en detenerse. Son segundos porque es un SO completo
   > que tiene que hacer shutdown limpio.

2. **Iniciar la VM** — Click en "Iniciar"
   > Tarda 30-60 segundos en arrancar. Es un SO completo booteando.
   > Cuando veamos contenedores, esto va a ser instantaneo.

3. **Mostrar metricas** — Ir a "Metricas" en el menu lateral
   > Aqui pueden ver CPU, red, disco. Azure monitorea todo a nivel de hipervisor.

**Limpieza** (si los alumnos quieren evitar costos):

```bash
# Pueden eliminar todo el grupo de recursos
az group delete --name rg-curso-k8s-lab1 --yes --no-wait
# O desde el Portal: Grupos de recursos > rg-curso-k8s-lab1 > Eliminar
```

> Si quieren mantener la VM para practicar, asegurense de DETENERLA cuando no la usen.
> Azure cobra por VM encendida.

---

## BLOQUE 4: De VMs a Contenedores (9:35 - 9:55) — 20 min

### 9:35 - 9:45 | Limitaciones de VMs (10 min)

**Abrir**: Modulo 1 README — Seccion 7 "De la virtualizacion a los contenedores"

**Decir**:

> Acabamos de crear una VM. Funciono bien. Pero ahora piensen en esto:
> Si tengo una aplicacion web con 10 microservicios, necesito 10 VMs?

**Las 5 limitaciones**:

1. **Arranque lento**: vimos que tarda 30-60s. Imaginen escalar 50 instancias.
2. **Uso excesivo de recursos**: cada VM necesita 2+ GB solo para el SO guest
3. **Complejidad de actualizaciones**: 10 VMs = 10 SOs que parchear
4. **Escalabilidad limitada**: max 10-20 VMs por servidor
5. **Densidad baja**: si cada VM consume 2 GB, en 64 GB solo caben 32 VMs

**Decir**:

> Los contenedores resuelven TODO esto:
> - Arranque en 1-3 segundos (no minutos)
> - Pesan 50-500 MB (no gigabytes)
> - Comparten el kernel del host (no necesitan SO propio)
> - 100+ contenedores en un solo servidor
> - Kubernetes puede escalar automaticamente

---

### 9:45 - 9:55 | Comparativa final VMs vs Contenedores (10 min)

**Mostrar tabla del Area 1 README**:

| Aspecto | Maquinas Virtuales | Contenedores Docker |
|---------|-------------------|---------------------|
| SO Guest | SO completo (2-4 GB) | Comparte kernel del host |
| Tamanio | GB (2-20 GB) | MB (50-500 MB) |
| Arranque | Minutos | Segundos |
| Overhead | Alto (~20-30%) | Minimo (~5%) |
| Densidad | 5-20 VMs/servidor | 100+ contenedores/servidor |
| Aislamiento | Hardware-nivel | Proceso-nivel |
| Uso en K8s | **Nodes (Workers) son VMs** | **Pods ejecutan contenedores** |

**Punto clave final**:

> Miren la ultima fila. En Kubernetes, los Nodes (servidores) SON maquinas virtuales,
> y los Pods (unidades de trabajo) ejecutan contenedores DENTRO de esas VMs.
> Por eso necesitabamos entender virtualizacion primero.
>
> Las VMs y los contenedores no compiten — se complementan.

---

## BLOQUE 5: Cierre (9:55 - 10:00) — 5 min

### Checkpoint del Modulo 1

**Preguntar rapido al grupo** (levantar mano o respuesta verbal):

- [ ] Que es un hipervisor? Diferencia entre Tipo 1 y Tipo 2?
- [ ] Que hipervisor usa Azure? (Hyper-V, Tipo 1)
- [ ] 3 ventajas de virtualizacion? (consolidacion, aislamiento, snapshots)
- [ ] 3 desventajas? (overhead SO, arranque lento, licencias)
- [ ] Por que surgieron los contenedores? (resolver limitaciones de VMs)

### Tarea para la proxima sesion

> Para la proxima clase necesito que instalen Docker en sus equipos.
> Sigan la guia del Lab 01 de Docker:

**Mostrar**: [Lab 01 Docker Install](../../../area-1-fundamentos-docker/modulo-2-docker/laboratorios/lab-01-docker-install/README.md)

```bash
# Al final deben poder ejecutar:
docker --version
docker run hello-world
```

> Si tienen problemas con la instalacion, me escriben antes de la proxima sesion.

### Preview de la proxima sesion

> La proxima clase arrancamos directo con Docker:
> - Que es un contenedor (no es una "VM ligera")
> - Los 4 pilares: Contenedores, Imagenes, Dockerfiles, Docker Hub
> - Tecnologias Linux: namespaces, cgroups
> - Laboratorio: correr nginx, postgres, redis en segundos
>
> Buenas noches y nos vemos en la proxima sesion.

---

## Notas del instructor

### Materiales necesarios

- Acceso a portal.azure.com (cuenta propia o de demostracion)
- Terminal con SSH configurado
- Pantalla compartida o proyector

### Puntos criticos a no olvidar

1. **No saltar el lab**: los alumnos DEBEN crear la VM y conectarse. Es la experiencia tangible que conecta la teoria.
2. **Enfatizar la relacion VMs-Contenedores-K8s**: cada vez que expliques algo de VMs, conectalo con lo que viene despues.
3. **El overhead del SO guest**: es EL concepto que justifica los contenedores. Repetirlo varias veces.
4. **La tarea de instalar Docker es critica**: si no llegan con Docker instalado, la sesion 2 pierde 30+ minutos.

### Timing de seguridad

Si vas adelantado (+10 min), puedes:
- Hacer el Lab 3 de Azure CLI (crear VM por comandos)
- Mostrar un `docker run nginx` rapido como preview

Si vas atrasado (-10 min), puedes:
- Comprimir Seccion 4 (tipos de virtualizacion) a 10 min, solo mencionar servidores y VDI
- Reducir la gestion de ciclo de vida a solo detener/iniciar
