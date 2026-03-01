#!/usr/bin/env python3
"""Clean Area 2 module README.md files (modules 08-14) by removing header and trailing boilerplate."""

import shutil
import os

BASE = os.path.dirname(os.path.abspath(__file__))

modules = [
    {
        "dir": "modulo-08-services-endpoints",
        "title": "# Capitulo 10: Services y Service Discovery",
        "transition": "Con Deployments desplegamos aplicaciones. Ahora necesitamos que se comuniquen entre si y con el mundo exterior. Los Services proporcionan descubrimiento y balanceo de carga estable.",
        "header_end_marker": "## 📚 Contenido",
        "trailing_start_markers": ["## 📁 Ejemplos Prácticos"],
        "closing": """---

## Resumen del Capitulo

En este capitulo exploramos los Services de Kubernetes, la pieza clave para la comunicacion entre Pods y con el mundo exterior. Cubrimos los cuatro tipos de Service (ClusterIP, NodePort, LoadBalancer y ExternalName), el mecanismo de Endpoints que conecta Services con Pods, y los Services headless para casos como StatefulSets. Tambien vimos configuraciones de produccion como session affinity, externalTrafficPolicy y puertos multiples, ademas de las mejores practicas de naming, labels y seguridad. Con estos fundamentos, las aplicaciones desplegadas con Deployments ya pueden descubrirse y comunicarse de forma estable y balanceada.
""",
    },
    {
        "dir": "modulo-09-ingress-external-access",
        "title": "# Capitulo 11: Ingress y Acceso Externo",
        "transition": "Los Services conectan internamente. Ahora exponemos aplicaciones al exterior con Ingress Controllers, rutas HTTP y terminacion TLS.",
        "header_end_marker": "## Introducción",
        "trailing_start_markers": ["## Recursos Adicionales"],
        "closing": """---

## Resumen del Capitulo

En este capitulo aprendimos a exponer aplicaciones HTTP/HTTPS al exterior usando Ingress, una capa mas inteligente que NodePort o LoadBalancer. Vimos como instalar un Ingress Controller (nginx), configurar routing por path y por host, habilitar TLS con certificados, y aplicar anotaciones avanzadas como rewrite, rate limiting y sticky sessions. Tambien cubrimos patrones de produccion como canary deployments, alta disponibilidad del controller y la transicion hacia Gateway API. Con Ingress, un solo punto de entrada gestiona el trafico externo hacia multiples servicios internos de forma eficiente y segura.
""",
    },
    {
        "dir": "modulo-10-namespaces-organizacion",
        "title": "# Capitulo 12: Namespaces y Organizacion",
        "transition": "Con acceso externo resuelto, organizamos los recursos del cluster con Namespaces: aislamiento logico, multi-tenancy y convenciones de nombres.",
        "header_end_marker": "## Introducción",
        "trailing_start_markers": ["## Ejemplos Prácticos"],
        "closing": """---

## Resumen del Capitulo

En este capitulo cubrimos Namespaces, el mecanismo fundamental de organizacion en Kubernetes. Desde la creacion basica y los namespaces del sistema, pasando por contextos en kubeconfig, DNS cross-namespace, hasta ResourceQuotas y LimitRanges para control de recursos. Tambien exploramos patrones de organizacion (por entorno, equipo, proyecto), aislamiento con NetworkPolicies y RBAC, y estrategias de multi-tenancy. Con estos conocimientos, un cluster compartido puede dividirse de forma segura y gobernada entre multiples equipos y aplicaciones.
""",
    },
    {
        "dir": "modulo-11-resource-limits-pods",
        "title": "# Capitulo 13: Resource Limits en Pods",
        "transition": "Los Namespaces organizan. Ahora controlamos cuantos recursos consume cada Pod: requests, limits, y las consecuencias de no definirlos.",
        "header_end_marker": "## Introducción",
        "trailing_start_markers": ["## Laboratorios", "## Laboratorios\n\n### Lab"],
        "trailing_start_line_hint": 2330,
        "closing": """---

## Resumen del Capitulo

En este capitulo profundizamos en la gestion de recursos de CPU, memoria y almacenamiento efimero en Pods. Cubrimos la diferencia critica entre requests (minimo garantizado que usa el scheduler) y limits (maximo que enforza el kubelet), las tres clases de QoS (Guaranteed, Burstable, BestEffort), unidades de medicion, Pod-level resources, extended resources como GPUs, y el comportamiento del scheduler y el enforcement. Tambien vimos monitoreo con kubectl top, best practices de right-sizing, y troubleshooting de OOMKilled y CPU throttling. Definir recursos correctamente es la base para clusters estables y eficientes en produccion.
""",
    },
    {
        "dir": "modulo-12-health-checks-probes",
        "title": "# Capitulo 14: Health Checks y Probes",
        "transition": "Con recursos limitados, necesitamos saber si nuestras aplicaciones estan sanas. Las probes de Kubernetes detectan y recuperan contenedores que fallan.",
        "header_end_marker": "## Introducción",
        "trailing_start_markers": ["## Recursos Adicionales"],
        "closing": """---

## Resumen del Capitulo

En este capitulo aprendimos los tres tipos de probes que Kubernetes ofrece para verificar la salud de las aplicaciones: Startup (para arranques lentos), Liveness (para detectar contenedores colgados) y Readiness (para controlar el trafico). Cubrimos los mecanismos de verificacion (HTTP GET, TCP Socket, exec, gRPC), los parametros de configuracion (initialDelaySeconds, periodSeconds, failureThreshold), y como combinar multiples probes de forma efectiva. Tambien vimos best practices, named ports, graceful shutdown y troubleshooting de fallos comunes. Con probes bien configuradas, Kubernetes puede auto-recuperar aplicaciones y dirigir trafico solo a instancias que estan realmente listas para servir.
""",
    },
    {
        "dir": "modulo-13-configmaps-variables",
        "title": "# Capitulo 15: ConfigMaps y Variables de Entorno",
        "transition": "Las apps corren sanas. Ahora externalizamos su configuracion para no recompilar imagenes con cada cambio de entorno.",
        "header_end_marker": "## Introducción",
        "trailing_start_markers": ["## Recursos Adicionales"],
        "closing": """---

## Resumen del Capitulo

En este capitulo cubrimos la gestion de configuracion externa en Kubernetes siguiendo el principio de 12-Factor App. Desde variables de entorno basicas y field references (metadata del Pod), hasta ConfigMaps creados desde literales, archivos y directorios. Vimos como consumir ConfigMaps como variables de entorno (envFrom, valueFrom) y como volumenes montados, las diferencias de comportamiento en actualizaciones, y ConfigMaps inmutables para mejor rendimiento. Tambien tratamos mejores practicas de organizacion y troubleshooting de problemas comunes. Con ConfigMaps, las aplicaciones se vuelven portables entre entornos sin necesidad de reconstruir imagenes.
""",
    },
    {
        "dir": "modulo-14-secrets-data-sensible",
        "title": "# Capitulo 16: Secrets y Datos Sensibles",
        "transition": "Configuracion resuelta con ConfigMaps. Ahora protegemos los datos sensibles -- contrasenas, tokens, certificados TLS -- con Secrets.",
        "header_end_marker": "## Introducción a los Secrets",
        "trailing_start_markers": ["## Laboratorios Prácticos"],
        "closing": """---

## Resumen del Capitulo

En este capitulo aprendimos a gestionar datos sensibles con Kubernetes Secrets. Cubrimos los tipos de Secrets (Opaque, TLS, docker-registry, service-account-token), los multiples metodos de creacion (kubectl, YAML, stringData), y las formas de consumo (variables de entorno y volumenes). Profundizamos en las limitaciones de seguridad de base64, encryption at rest, RBAC estricto, y Secrets inmutables. Tambien exploramos herramientas externas como Sealed Secrets, HashiCorp Vault y External Secrets Operator para entornos de produccion. Con estos conocimientos, las credenciales y certificados de las aplicaciones se gestionan de forma controlada y auditable dentro del cluster.
""",
    },
]


def find_line_number(lines, marker, start_from=0):
    """Find the line number where a marker appears."""
    for i in range(start_from, len(lines)):
        if lines[i].strip().startswith(marker.strip()):
            return i
    return -1


def process_module(mod):
    readme_path = os.path.join(BASE, mod["dir"], "README.md")
    backup_path = os.path.join(BASE, mod["dir"], "README.md.backup")

    # Create backup
    shutil.copy2(readme_path, backup_path)
    print(f"  Backup: {backup_path}")

    # Read file
    with open(readme_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    total_lines = len(lines)
    print(f"  Total lines: {total_lines}")

    # Find header end (where content starts)
    header_end = find_line_number(lines, mod["header_end_marker"])
    if header_end == -1:
        print(f"  ERROR: Could not find header end marker: {mod['header_end_marker']}")
        return False

    # Go back to include the --- separator before the content marker
    # We want to start from the content marker line itself
    content_start = header_end
    print(f"  Content starts at line: {content_start + 1} ('{lines[content_start].strip()}')")

    # Find trailing start
    trailing_start = -1
    search_from = len(lines) // 2  # Start from halfway to avoid false positives

    if "trailing_start_line_hint" in mod:
        search_from = mod["trailing_start_line_hint"] - 10

    for marker in mod["trailing_start_markers"]:
        trailing_start = find_line_number(lines, marker.strip(), search_from)
        if trailing_start != -1:
            break

    if trailing_start == -1:
        print(f"  ERROR: Could not find trailing start marker")
        return False

    # Go back to include the --- separator before trailing
    # Find the --- before the trailing marker
    trail_with_sep = trailing_start
    for i in range(trailing_start - 1, max(trailing_start - 5, 0), -1):
        if lines[i].strip() == "---":
            trail_with_sep = i
            break
        elif lines[i].strip() == "":
            continue
        else:
            break

    print(f"  Trailing starts at line: {trail_with_sep + 1} (near '{lines[trailing_start].strip()}')")

    # Extract content between header and trailing
    content_lines = lines[content_start:trail_with_sep]

    # Remove leading/trailing blank lines from content
    while content_lines and content_lines[0].strip() == "":
        content_lines.pop(0)
    while content_lines and content_lines[-1].strip() == "":
        content_lines.pop()

    print(f"  Content lines extracted: {len(content_lines)}")

    # Build new file
    new_content = []
    new_content.append(mod["title"] + "\n")
    new_content.append("\n")
    new_content.append(mod["transition"] + "\n")
    new_content.append("\n")
    new_content.append("---\n")
    new_content.append("\n")
    new_content.extend(content_lines)
    new_content.append("\n")
    new_content.append(mod["closing"])

    # Write new file
    with open(readme_path, "w", encoding="utf-8") as f:
        f.writelines(new_content)

    new_total = len(new_content)
    print(f"  New file lines: {new_total}")
    print(f"  Removed: {total_lines - new_total} lines")
    return True


def main():
    print("Cleaning Area 2 module README.md files (modules 08-14)")
    print("=" * 60)

    for mod in modules:
        print(f"\nProcessing: {mod['dir']}")
        success = process_module(mod)
        if success:
            print(f"  DONE")
        else:
            print(f"  FAILED")


if __name__ == "__main__":
    main()
