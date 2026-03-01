#!/usr/bin/env python3
import os, sys

base = "/media/Data/Source/Courses/K8S/area-2-arquitectura-kubernetes"

modules = [
    ("modulo-01-introduccion-kubernetes", "# Cap\u00edtulo 3: Introducci\u00f3n a Kubernetes", "Ahora que dominamos Docker, es momento de conocer el sistema que orquesta contenedores a escala: Kubernetes. Descubrimos su origen en Google, su prop\u00f3sito y los problemas que resuelve.", 202, 1149, "## Cierre del cap\u00edtulo\n\nEn este cap\u00edtulo hemos recorrido el origen de Kubernetes, desde Google Borg hasta el proyecto open-source que domina la industria. Comprendimos los problemas concretos que resuelve \u2014orquestaci\u00f3n, escalado autom\u00e1tico, self-healing\u2014 y evaluamos cu\u00e1ndo tiene sentido adoptarlo y cu\u00e1ndo no. Con este contexto claro, estamos preparados para sumergirnos en la arquitectura interna de un cluster."),
    ("modulo-02-arquitectura-cluster", "# Cap\u00edtulo 4: Arquitectura de un Cluster Kubernetes", "Con Kubernetes presentado, exploramos su arquitectura interna: el plano de control, los nodos worker y c\u00f3mo cada componente contribuye al funcionamiento del cluster.", 267, 2156, "## Cierre del cap\u00edtulo\n\nHemos desmontado pieza a pieza la arquitectura de un cluster Kubernetes: el API Server como punto \u00fanico de entrada, etcd como almac\u00e9n de verdad, el Scheduler decidiendo d\u00f3nde ubicar Pods, y los controllers manteniendo el estado deseado. En los Worker Nodes, kubelet, kube-proxy y el container runtime ejecutan las cargas reales. Con esta visi\u00f3n completa del sistema, estamos listos para instalar nuestro propio cluster y verlo funcionar."),
    ("modulo-03-instalacion-minikube", "# Cap\u00edtulo 5: Instalaci\u00f3n de Minikube", "Ya entendemos los componentes. Ahora instalemos nuestro primer cluster local con Minikube para tener un entorno de pr\u00e1ctica funcional.", 384, 1237, "## Cierre del cap\u00edtulo\n\nHemos instalado y configurado un entorno local completo: Docker como runtime, kubectl como herramienta CLI, y Minikube como cluster de un solo nodo. Verificamos que todos los componentes del Control Plane y Worker est\u00e1n corriendo, desplegamos nuestra primera aplicaci\u00f3n, y aprendimos a diagnosticar problemas comunes. A partir de ahora, todos los m\u00f3dulos pr\u00e1cticos utilizar\u00e1n este entorno."),
    ("modulo-04-pods-vs-contenedores", "# Cap\u00edtulo 6: Pods vs Contenedores Docker", "Con Minikube funcionando, exploramos la unidad m\u00ednima de ejecuci\u00f3n en Kubernetes: el Pod. Veremos c\u00f3mo se diferencia de un contenedor Docker y por qu\u00e9 Kubernetes a\u00f1ade esta capa de abstracci\u00f3n.", 443, 1995, "## Cierre del cap\u00edtulo\n\nComprendimos que un Pod no es simplemente un contenedor mejorado, sino una abstracci\u00f3n que agrupa contenedores con red, IPC y almacenamiento compartidos. Exploramos el contenedor pause como infraestructura invisible, los patrones Sidecar, Init Container y Ambassador, y las diferencias fundamentales entre el modelo Docker y el modelo Kubernetes. Con este conocimiento, podemos dise\u00f1ar Pods efectivos y pasar a su gesti\u00f3n operativa avanzada."),
    ("modulo-05-gestion-pods", "# Cap\u00edtulo 7: Gesti\u00f3n Avanzada de Pods", "Sabemos qu\u00e9 es un Pod. Ahora aprendemos a gestionarlos en el d\u00eda a d\u00eda: ciclo de vida, especificaciones avanzadas, debugging y buenas pr\u00e1cticas.", 438, 3877, "## Cierre del cap\u00edtulo\n\nDominamos la gesti\u00f3n operativa de Pods: manifiestos YAML production-ready, resource requests y limits con sus clases QoS, health checks (liveness, readiness, startup), security contexts con privilegios m\u00ednimos, y t\u00e9cnicas de debugging avanzado. Cada Pod que creemos en adelante seguir\u00e1 estas buenas pr\u00e1cticas, prepar\u00e1ndonos para escalar con ReplicaSets."),
    ("modulo-06-replicasets-replicas", "# Cap\u00edtulo 8: ReplicaSets y Escalado", "Gestionar Pods individuales no escala. Los ReplicaSets garantizan que el n\u00famero deseado de r\u00e9plicas est\u00e9 siempre corriendo, proporcionando auto-healing y escalado horizontal.", 406, 2690, "## Cierre del cap\u00edtulo\n\nLos ReplicaSets nos dieron la capacidad de mantener N r\u00e9plicas de un Pod corriendo en todo momento. Entendimos el reconciliation loop, los label selectors (matchLabels y matchExpressions), la auto-recuperaci\u00f3n ante fallos, y las limitaciones que justifican usar Deployments en producci\u00f3n. Con esta base s\u00f3lida en controladores, estamos listos para a\u00f1adir gesti\u00f3n de versiones con Deployments."),
    ("modulo-07-deployments-rollouts", "# Cap\u00edtulo 9: Deployments y Rollouts", "Los ReplicaSets mantienen Pods vivos, pero no gestionan actualizaciones. Los Deployments a\u00f1aden rolling updates, rollbacks y estrategias de despliegue declarativas.", 493, 3545, "## Cierre del cap\u00edtulo\n\nLos Deployments completan la pir\u00e1mide de workloads: gestionan ReplicaSets, habilitan rolling updates sin downtime, permiten rollbacks instant\u00e1neos, y soportan estrategias avanzadas como Blue-Green y Canary. Aprendimos a controlar la velocidad de despliegue con maxSurge y maxUnavailable, a inspeccionar el historial de revisiones, y a diagnosticar rollouts fallidos. Este es el recurso est\u00e1ndar para desplegar aplicaciones en Kubernetes."),
]

mode = sys.argv[1] if len(sys.argv) > 1 else "verify"

for d, title, transition, cs, ts, closing in modules:
    fp = os.path.join(base, d, "README.md.backup")
    with open(fp, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    cl = lines[cs-1:ts-1]
    while cl and cl[-1].strip() == '':
        cl.pop()
    while cl and cl[-1].strip() == '---':
        cl.pop()
    while cl and cl[-1].strip() == '':
        cl.pop()
    if mode == "verify":
        print(f"{d}: {len(lines)} -> {len(cl)} lines")
        print(f"  First: {cl[0].rstrip()[:90]}")
        print(f"  Last:  {cl[-1].rstrip()[:90]}")
    elif mode == "write":
        ct = ''.join(cl)
        nr = title + "\n\n" + transition + "\n\n---\n\n" + ct + "\n\n---\n\n" + closing + "\n"
        op = os.path.join(base, d, "README.md")
        with open(op, 'w', encoding='utf-8') as f:
            f.write(nr)
        with open(op, 'r', encoding='utf-8') as f:
            nl = f.readlines()
        print(f"{d}: {len(lines)} -> {len(nl)} lines written")
