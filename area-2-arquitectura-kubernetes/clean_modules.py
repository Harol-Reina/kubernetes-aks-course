#!/usr/bin/env python3
"""Clean module READMEs: remove header/trailing boilerplate, add chapter format."""
import os
import re
import shutil

BASE = os.path.dirname(os.path.abspath(__file__))

# (dir_name, chapter_num, title, transition, approx_header_end, approx_trailing_lines)
MODULES = [
    ("modulo-01-introduccion-kubernetes", 3, "Introducción a Kubernetes",
     "Ahora que dominamos Docker, es momento de conocer el sistema que orquesta contenedores a escala: Kubernetes. Descubrimos su origen en Google, su propósito y los problemas que resuelve.",
     200, 25),
    ("modulo-02-arquitectura-cluster", 4, "Arquitectura de un Cluster Kubernetes",
     "Con Kubernetes presentado, exploramos su arquitectura interna: el plano de control, los nodos worker y cómo cada componente contribuye al funcionamiento del cluster.",
     265, 25),
    ("modulo-03-instalacion-minikube", 5, "Instalación de Minikube",
     "Ya entendemos los componentes. Ahora instalemos nuestro primer cluster local con Minikube para tener un entorno de práctica funcional.",
     381, 25),
    ("modulo-04-pods-vs-contenedores", 6, "Pods vs Contenedores Docker",
     "Con Minikube funcionando, exploramos la unidad mínima de ejecución en Kubernetes: el Pod. Veremos cómo se diferencia de un contenedor Docker y por qué Kubernetes añade esta capa de abstracción.",
     318, 25),
    ("modulo-05-gestion-pods", 7, "Gestión Avanzada de Pods",
     "Sabemos qué es un Pod. Ahora aprendemos a gestionarlos en el día a día: ciclo de vida, especificaciones avanzadas, debugging y buenas prácticas.",
     435, 26),
    ("modulo-06-replicasets-replicas", 8, "ReplicaSets y Escalado",
     "Gestionar Pods individuales no escala. Los ReplicaSets garantizan que el número deseado de réplicas esté siempre corriendo, proporcionando auto-healing y escalado horizontal.",
     404, 25),
    ("modulo-07-deployments-rollouts", 9, "Deployments y Rollouts",
     "Los ReplicaSets mantienen Pods vivos, pero no gestionan actualizaciones. Los Deployments añaden rolling updates, rollbacks y estrategias de despliegue declarativas.",
     411, 27),
    ("modulo-08-services-endpoints", 10, "Services y Service Discovery",
     "Con Deployments desplegamos aplicaciones. Ahora necesitamos que se comuniquen entre sí y con el mundo exterior. Los Services proporcionan descubrimiento y balanceo de carga estable.",
     164, 26),
    ("modulo-09-ingress-external-access", 11, "Ingress y Acceso Externo",
     "Los Services conectan internamente. Ahora exponemos aplicaciones al exterior con Ingress Controllers, rutas HTTP y terminación TLS.",
     185, 25),
    ("modulo-10-namespaces-organizacion", 12, "Namespaces y Organización",
     "Con acceso externo resuelto, organizamos los recursos del cluster con Namespaces: aislamiento lógico, multi-tenancy y convenciones de nombres.",
     187, 26),
    ("modulo-11-resource-limits-pods", 13, "Resource Limits en Pods",
     "Los Namespaces organizan. Ahora controlamos cuántos recursos consume cada Pod: requests, limits, y las consecuencias de no definirlos.",
     218, 25),
    ("modulo-12-health-checks-probes", 14, "Health Checks y Probes",
     "Con recursos limitados, necesitamos saber si nuestras aplicaciones están sanas. Las probes de Kubernetes detectan y recuperan contenedores que fallan.",
     190, 22),
    ("modulo-13-configmaps-variables", 15, "ConfigMaps y Variables de Entorno",
     "Las apps corren sanas. Ahora externalizamos su configuración para no recompilar imágenes con cada cambio de entorno.",
     210, 29),
    ("modulo-14-secrets-data-sensible", 16, "Secrets y Datos Sensibles",
     "Configuración resuelta con ConfigMaps. Ahora protegemos los datos sensibles — contraseñas, tokens, certificados TLS — con Secrets.",
     204, 29),
    ("modulo-15-volumes-conceptos", 17, "Volumes — Conceptos",
     "La configuración vive en ConfigMaps y Secrets. Pero los datos generados en runtime — bases de datos, logs, archivos subidos — necesitan persistencia. Entramos al mundo de los volúmenes.",
     233, 29),
    ("modulo-16-volumes-tipos-storage", 18, "Volumes — Tipos y Storage",
     "Con los conceptos de volúmenes claros, implementamos storage real: EmptyDir, HostPath, PersistentVolumes, PersistentVolumeClaims y StorageClasses.",
     312, 29),
    ("modulo-17-rbac-users-groups", 19, "RBAC — Users y Groups",
     "Los datos persisten. Ahora controlamos quién accede a qué dentro del cluster. RBAC (Role-Based Access Control) define permisos granulares para usuarios y grupos.",
     360, 29),
    ("modulo-18-rbac-serviceaccounts", 20, "RBAC — ServiceAccounts",
     "RBAC protege el acceso humano. Pero las aplicaciones también necesitan permisos para interactuar con la API de Kubernetes. Los ServiceAccounts resuelven esta necesidad.",
     367, 29),
    ("modulo-19-jobs-cronjobs", 21, "Jobs y CronJobs",
     "Con seguridad resuelta, expandimos los tipos de workload. No todo es un servidor web: los Jobs ejecutan tareas finitas y los CronJobs las programan en el tiempo.",
     64, 29),
    ("modulo-20-init-sidecar-patterns", 22, "Init Containers y Sidecar Patterns",
     "Los Jobs ejecutan tareas finitas. Los patrones multi-contenedor van más allá de un contenedor por Pod: Init Containers preparan, Sidecars acompañan y Ambassadors representan.",
     305, 30),
    ("modulo-21-helm-basics", 23, "Helm — Gestor de Paquetes",
     "Los patrones están claros. Pero gestionar decenas de manifiestos YAML por aplicación es tedioso. Helm empaqueta todo en charts reutilizables y parametrizables.",
     112, 29),
    ("modulo-22-cluster-setup-kubeadm", 24, "Cluster Setup con kubeadm",
     "Helm empaqueta aplicaciones. Ahora montamos clusters reales desde cero con kubeadm: inicialización del control plane, unión de nodos y configuración de red.",
     44, 29),
    ("modulo-23-maintenance-upgrades", 25, "Mantenimiento y Upgrades",
     "El cluster está montado. Ahora lo mantenemos operativo: backups de etcd, upgrades de versión, drain de nodos y procedimientos de recuperación.",
     31, 29),
    ("modulo-24-advanced-scheduling", 26, "Advanced Scheduling",
     "El cluster se mantiene solo. Ahora controlamos dónde corren los Pods: afinidad, anti-afinidad, taints, tolerations y topología de distribución.",
     76, 24),
    ("modulo-25-networking", 27, "Networking Avanzado",
     "El scheduling decide dónde corren los Pods. Ahora profundizamos en cómo se comunican: modelo de red, CNI plugins, DNS interno y Network Policies.",
     38, 29),
    ("modulo-26-troubleshooting", 28, "Troubleshooting",
     "Todo funciona... hasta que falla. Este capítulo proporciona un framework sistemático para diagnosticar y resolver problemas en Kubernetes: desde Pods que no arrancan hasta clusters que no responden.",
     17, 29),
]

# Patterns that indicate boilerplate header sections
BOILERPLATE_PATTERNS = [
    r'##\s*📋\s*Objetivos',
    r'##\s*🎯\s*Objetivos',
    r'##\s*Objetivos de Aprendizaje',
    r'##\s*✅\s*Prerrequisitos',
    r'##\s*Prerrequisitos',
    r'##\s*🗺️\s*Estructura',
    r'##\s*Estructura del Módulo',
    r'##\s*📚\s*Rutas de Estudio',
    r'##\s*Rutas de Estudio',
    r'##\s*🎯\s*Metodología',
    r'##\s*Metodología',
    r'##\s*🔗\s*Conexión',
    r'##\s*Conexión con',
    r'##\s*💡\s*Conceptos',
    r'##\s*Conceptos Clave Previos',
    r'##\s*📁\s*Organización',
    r'##\s*Organización de Recursos',
    r'##\s*🔬\s*Laboratorios',
    r'##\s*Índice',
    r'##\s*Tabla de Contenidos',
    r'##\s*📋\s*Expanded Objectives',
    r'##\s*Objetivos Expandidos',
    r'##\s*🔧\s*Herramientas',
    r'##\s*📊\s*Distribución',
]

# Patterns that indicate trailing sections
TRAILING_PATTERNS = [
    r'##\s*🧠\s*Resultado [Ee]sperado',
    r'##\s*Resultado [Ee]sperado',
    r'##\s*📋\s*Checkpoint',
    r'##\s*Checkpoint del Módulo',
    r'##\s*⏭️\s*Navegación',
    r'##\s*Navegación',
    r'##\s*📂\s*Recursos del Módulo',
    r'##\s*📚\s*Fuentes',
    r'##\s*Fuentes y [Rr]eferencias',
    r'##\s*🔗\s*Referencias',
    r'##\s*Referencias\s*$',
    r'##\s*🎓\s*Evaluación',
    r'##\s*📊\s*Evaluación',
    r'##\s*🔄\s*Evaluación',
    r'##\s*Siguiente Módulo',
    r'##\s*⏭️\s*Siguiente',
    r'##\s*▶️\s*Siguiente',
    r'##\s*▶️\s*Navegación',
]


def is_boilerplate_heading(line):
    """Check if a line matches a boilerplate heading pattern."""
    for pat in BOILERPLATE_PATTERNS:
        if re.search(pat, line):
            return True
    return False


def is_trailing_heading(line):
    """Check if a line matches a trailing section pattern."""
    for pat in TRAILING_PATTERNS:
        if re.search(pat, line):
            return True
    return False


def is_content_heading(line):
    """Check if a line looks like a content (teaching) heading."""
    if not line.startswith('## '):
        return False
    if is_boilerplate_heading(line):
        return False
    if is_trailing_heading(line):
        return False
    return True


def find_content_start(lines, approx_header_end):
    """Find the first content heading after the boilerplate header."""
    # Strategy: scan from line 0 looking for the first content heading
    # that's NOT a boilerplate heading. Use approx_header_end as hint.

    # First, try to find content heading near the approximate boundary
    search_start = max(0, approx_header_end - 50)
    search_end = min(len(lines), approx_header_end + 100)

    for i in range(search_start, search_end):
        line = lines[i].rstrip()
        if line.startswith('## ') and is_content_heading(line):
            return i

    # If not found near boundary, scan from beginning
    # Skip first heading (title) and look for first content heading
    in_boilerplate = True
    for i in range(2, len(lines)):
        line = lines[i].rstrip()
        if line.startswith('## '):
            if is_content_heading(line):
                # Only accept if we're past a reasonable header size (> 15 lines)
                if i > 15:
                    return i
            in_boilerplate = True

    # Fallback: use approximate value
    return approx_header_end


def find_trailing_start(lines, approx_trailing_lines):
    """Find where trailing boilerplate begins, scanning from bottom."""
    total = len(lines)

    # Scan from the bottom up, looking for trailing headings
    search_start = max(0, total - approx_trailing_lines - 40)

    trailing_start = total  # default: no trailing

    for i in range(total - 1, search_start, -1):
        line = lines[i].rstrip()
        if line.startswith('## ') and is_trailing_heading(line):
            trailing_start = i

    # Also look for common trailing markers like "---" followed by navigation
    if trailing_start == total:
        # Try to find the last "---" separator followed by trailing content
        for i in range(total - 1, search_start, -1):
            line = lines[i].rstrip()
            if line == '---' and i > total - approx_trailing_lines - 20:
                # Check if what follows is trailing
                for j in range(i+1, min(i+5, total)):
                    if lines[j].strip().startswith('##') and is_trailing_heading(lines[j]):
                        trailing_start = i
                        break

    return trailing_start


def generate_closing(title, chapter_num):
    """Generate a brief closing summary."""
    return f"""
---

## Resumen del Capítulo

Este capítulo cubrió los conceptos fundamentales de {title.lower()}, desde la teoría hasta la práctica con ejemplos y manifiestos YAML aplicables en entornos reales. Los laboratorios en el directorio `laboratorios/` permiten practicar cada concepto, y el `RESUMEN-MODULO.md` sirve como guía de repaso rápido.
"""


def process_module(dir_name, chapter_num, title, transition, approx_header_end, approx_trailing_lines):
    """Process a single module README."""
    module_path = os.path.join(BASE, dir_name)
    readme_path = os.path.join(module_path, 'README.md')
    backup_path = os.path.join(module_path, 'README.md.backup')

    # Ensure backup exists
    if not os.path.exists(backup_path):
        if os.path.exists(readme_path):
            shutil.copy2(readme_path, backup_path)
            print(f"  Created backup: {dir_name}/README.md.backup")
        else:
            print(f"  SKIP: {dir_name}/README.md not found")
            return False

    # Read from backup (original content)
    with open(backup_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    total_lines = len(lines)

    # Find boundaries
    content_start = find_content_start(lines, approx_header_end)
    trailing_start = find_trailing_start(lines, approx_trailing_lines)

    # Sanity checks
    if content_start >= trailing_start:
        print(f"  WARNING: {dir_name} - content_start ({content_start}) >= trailing_start ({trailing_start})")
        print(f"    Using approx values: header_end={approx_header_end}, trailing={total_lines - approx_trailing_lines}")
        content_start = approx_header_end
        trailing_start = total_lines - approx_trailing_lines

    # Extract content
    content_lines = lines[content_start:trailing_start]

    # Strip leading/trailing blank lines from content
    while content_lines and content_lines[0].strip() == '':
        content_lines.pop(0)
    while content_lines and content_lines[-1].strip() == '':
        content_lines.pop()

    content = ''.join(content_lines)

    # Build new file
    header = f"# Capítulo {chapter_num}: {title}\n\n{transition}\n\n---\n\n"
    closing = generate_closing(title, chapter_num)

    new_content = header + content + closing

    # Write
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    content_count = len(content_lines)
    removed_header = content_start
    removed_trailing = total_lines - trailing_start

    print(f"  OK: {dir_name} -> Cap {chapter_num}: {title}")
    print(f"      Total: {total_lines} -> Content: {content_count} lines")
    print(f"      Removed: {removed_header} header + {removed_trailing} trailing = {removed_header + removed_trailing} lines")

    return True


def main():
    print("=" * 60)
    print("Cleaning Area 2 module READMEs")
    print("=" * 60)

    success = 0
    fail = 0

    for mod in MODULES:
        print(f"\nProcessing {mod[0]}...")
        if process_module(*mod):
            success += 1
        else:
            fail += 1

    print(f"\n{'=' * 60}")
    print(f"Done: {success} cleaned, {fail} failed")
    print(f"{'=' * 60}")


if __name__ == '__main__':
    main()
