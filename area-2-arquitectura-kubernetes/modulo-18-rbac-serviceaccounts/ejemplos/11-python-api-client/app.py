#!/usr/bin/env python3
"""
Script de ejemplo: Listar pods usando la API de Kubernetes

Este script demuestra cómo una aplicación Python corriendo en Kubernetes
puede interactuar con la API usando el Service Account del pod.

Requisitos:
- pip install kubernetes

Uso dentro de un pod:
    python app.py

Uso fuera del cluster (requiere kubeconfig):
    python app.py --kubeconfig ~/.kube/config
"""

from kubernetes import client, config
from kubernetes.client.rest import ApiException
import argparse
import sys


def setup_config(use_kubeconfig=False, kubeconfig_path=None):
    """Configura el cliente de Kubernetes"""
    try:
        if use_kubeconfig:
            # Cargar desde archivo kubeconfig (desarrollo local)
            config.load_kube_config(config_file=kubeconfig_path)
            print("✅ Configuración cargada desde kubeconfig")
        else:
            # Cargar desde dentro del cluster (producción)
            config.load_incluster_config()
            print("✅ Configuración cargada desde Service Account")
        return True
    except Exception as e:
        print(f"❌ Error cargando configuración: {e}")
        return False


def get_current_namespace():
    """Obtiene el namespace actual desde el Service Account"""
    try:
        with open("/var/run/secrets/kubernetes.io/serviceaccount/namespace", "r") as f:
            return f.read().strip()
    except FileNotFoundError:
        # Si no estamos en un pod, usar 'default'
        return "default"


def list_pods(namespace=None):
    """Lista todos los pods en el namespace especificado"""
    v1 = client.CoreV1Api()
    
    if namespace is None:
        namespace = get_current_namespace()
    
    print(f"\n📦 Namespace: {namespace}")
    print("=" * 60)
    
    try:
        # Listar pods
        pods = v1.list_namespaced_pod(namespace=namespace)
        
        if not pods.items:
            print("ℹ️  No hay pods en este namespace")
            return
        
        print(f"\n📋 Encontrados {len(pods.items)} pods:\n")
        
        for i, pod in enumerate(pods.items, 1):
            print(f"{i}. {pod.metadata.name}")
            print(f"   📍 Estado: {pod.status.phase}")
            print(f"   🌐 IP: {pod.status.pod_ip or 'N/A'}")
            print(f"   🖥️  Nodo: {pod.spec.node_name or 'N/A'}")
            print(f"   🏷️  Labels: {pod.metadata.labels}")
            
            # Mostrar containers
            if pod.spec.containers:
                print(f"   📦 Contenedores:")
                for container in pod.spec.containers:
                    print(f"      - {container.name} ({container.image})")
            
            print()
    
    except ApiException as e:
        if e.status == 403:
            print(f"\n❌ Acceso denegado: El Service Account no tiene permisos")
            print(f"   Necesitas crear un Role con 'get' y 'list' en pods")
        else:
            print(f"\n❌ Error accediendo a la API: {e.status} - {e.reason}")


def get_pod_logs(pod_name, namespace=None, container=None):
    """Obtiene los logs de un pod específico"""
    v1 = client.CoreV1Api()
    
    if namespace is None:
        namespace = get_current_namespace()
    
    try:
        print(f"\n📜 Logs del pod '{pod_name}' en namespace '{namespace}':")
        print("=" * 60)
        
        logs = v1.read_namespaced_pod_log(
            name=pod_name,
            namespace=namespace,
            container=container,
            tail_lines=50  # Últimas 50 líneas
        )
        
        print(logs)
    
    except ApiException as e:
        if e.status == 404:
            print(f"❌ Pod '{pod_name}' no encontrado")
        elif e.status == 403:
            print(f"❌ Acceso denegado: El Service Account no tiene permisos para leer logs")
        else:
            print(f"❌ Error: {e.status} - {e.reason}")


def watch_pods(namespace=None, timeout_seconds=60):
    """Observa cambios en pods en tiempo real"""
    from kubernetes import watch
    
    v1 = client.CoreV1Api()
    w = watch.Watch()
    
    if namespace is None:
        namespace = get_current_namespace()
    
    print(f"\n👀 Observando cambios en pods del namespace '{namespace}'...")
    print("   (Presiona Ctrl+C para detener)\n")
    
    try:
        for event in w.stream(
            v1.list_namespaced_pod,
            namespace=namespace,
            timeout_seconds=timeout_seconds
        ):
            pod = event['object']
            event_type = event['type']
            
            print(f"[{event_type}] {pod.metadata.name} - {pod.status.phase}")
    
    except KeyboardInterrupt:
        print("\n\nObservación detenida")
    except ApiException as e:
        if e.status == 403:
            print(f"❌ Acceso denegado: El Service Account necesita permiso 'watch' en pods")
        else:
            print(f"❌ Error: {e.status} - {e.reason}")


def get_service_account_info():
    """Muestra información del Service Account actual"""
    try:
        with open("/var/run/secrets/kubernetes.io/serviceaccount/namespace", "r") as f:
            namespace = f.read().strip()
        
        print("\n🔑 Información del Service Account:")
        print("=" * 60)
        print(f"   Namespace: {namespace}")
        
        # El nombre del SA está en las variables de entorno o en el pod spec
        # En este ejemplo básico solo mostramos el namespace
        print(f"   Token montado en: /var/run/secrets/kubernetes.io/serviceaccount/token")
        print(f"   CA cert en: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
        
    except FileNotFoundError:
        print("ℹ️  No se está ejecutando dentro de un pod de Kubernetes")


def main():
    parser = argparse.ArgumentParser(
        description="Cliente de API de Kubernetes usando Service Account"
    )
    parser.add_argument(
        "--kubeconfig",
        help="Ruta al archivo kubeconfig (para desarrollo local)",
        default=None
    )
    parser.add_argument(
        "--namespace",
        "-n",
        help="Namespace a consultar (por defecto: namespace actual)",
        default=None
    )
    parser.add_argument(
        "--logs",
        help="Obtener logs de un pod específico",
        metavar="POD_NAME"
    )
    parser.add_argument(
        "--watch",
        action="store_true",
        help="Observar cambios en pods en tiempo real"
    )
    
    args = parser.parse_args()
    
    # Configurar cliente
    use_kubeconfig = args.kubeconfig is not None
    if not setup_config(use_kubeconfig, args.kubeconfig):
        sys.exit(1)
    
    # Mostrar info del SA si estamos en un pod
    if not use_kubeconfig:
        get_service_account_info()
    
    # Ejecutar acción solicitada
    if args.logs:
        get_pod_logs(args.logs, args.namespace)
    elif args.watch:
        watch_pods(args.namespace)
    else:
        list_pods(args.namespace)


if __name__ == "__main__":
    main()
