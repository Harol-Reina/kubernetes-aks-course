#!/bin/bash

##############################################################################
# Script de Limpieza - Lab Resumen: Almacenamiento Persistente
#
# Descripcion: Elimina todos los recursos del laboratorio de almacenamiento:
#              namespace lab-almacenamiento (Pods, PVCs, StatefulSet, Service,
#              ConfigMap), PersistentVolumes del cluster (pv-datos), y
#              StorageClass storage-local. Restaura el namespace por defecto.
#
# Uso: ./cleanup.sh
#
# Nota sobre PersistentVolumes:
#   Los PVs son recursos del cluster (no del namespace) y NO se eliminan
#   al borrar el namespace. Este script los elimina explicitamente.
#   Si la ReclaimPolicy es "Retain", los datos en el nodo Minikube
#   persisten hasta que se eliminen manualmente con: minikube ssh "rm -rf /data/pv-datos"
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}Limpieza del Lab Resumen: Almacenamiento Persistente...${NC}"
echo

# -------------------------------------------------------------------
# 1) Eliminar el namespace (incluye Pods, PVCs, StatefulSet, Service, ConfigMap)
# -------------------------------------------------------------------
echo -e "${BLUE}[1/4] Eliminando namespace lab-almacenamiento...${NC}"
if kubectl get namespace lab-almacenamiento &> /dev/null; then
    kubectl delete namespace lab-almacenamiento --timeout=60s
    echo -e "  ${GREEN}namespace/lab-almacenamiento eliminado${NC}"
    echo -e "  ${GREEN}  Incluye: pod-escritor, pod-verificador, statefulset-db${NC}"
    echo -e "  ${GREEN}  Incluye: pvc-datos, datos-db-statefulset-db-0, datos-db-statefulset-db-1${NC}"
    echo -e "  ${GREEN}  Incluye: db-headless (Service), storage-info (ConfigMap)${NC}"
else
    echo -e "  ${YELLOW}namespace/lab-almacenamiento no existe (skip)${NC}"
fi

echo

# -------------------------------------------------------------------
# 2) Eliminar PersistentVolumes (recursos del cluster, no del namespace)
# -------------------------------------------------------------------
echo -e "${BLUE}[2/4] Eliminando PersistentVolumes del cluster...${NC}"
if kubectl get pv pv-datos &> /dev/null; then
    kubectl delete pv pv-datos --ignore-not-found=true
    echo -e "  ${GREEN}persistentvolume/pv-datos eliminado${NC}"
else
    echo -e "  ${YELLOW}persistentvolume/pv-datos no existe (skip)${NC}"
fi

# Eliminar PVs remanentes del StatefulSet (si quedaron en estado Released)
PVCS_REMANENTES=$(kubectl get pv --no-headers 2>/dev/null | grep "datos-db-statefulset-db" | awk '{print $1}' || true)
if [ -n "$PVCS_REMANENTES" ]; then
    echo -e "  Eliminando PVs remanentes del StatefulSet..."
    for pv in $PVCS_REMANENTES; do
        kubectl delete pv "$pv" --ignore-not-found=true
        echo -e "  ${GREEN}persistentvolume/$pv eliminado${NC}"
    done
else
    echo -e "  ${YELLOW}No hay PVs remanentes del StatefulSet (skip)${NC}"
fi

echo

# -------------------------------------------------------------------
# 3) Eliminar StorageClass del lab
# -------------------------------------------------------------------
echo -e "${BLUE}[3/4] Eliminando StorageClass storage-local...${NC}"
if kubectl get storageclass storage-local &> /dev/null; then
    kubectl delete storageclass storage-local --ignore-not-found=true
    echo -e "  ${GREEN}storageclass/storage-local eliminada${NC}"
else
    echo -e "  ${YELLOW}storageclass/storage-local no existe (skip)${NC}"
fi

echo

# -------------------------------------------------------------------
# 4) Restaurar contexto al namespace por defecto
# -------------------------------------------------------------------
echo -e "${BLUE}[4/4] Restaurando contexto...${NC}"
kubectl config set-context --current --namespace=default 2>/dev/null || true
echo -e "  ${GREEN}Contexto restaurado a namespace 'default'${NC}"

echo
echo -e "${GREEN}Limpieza completada!${NC}"
echo
echo -e "${YELLOW}Nota: Los datos del hostPath en el nodo Minikube persisten.${NC}"
echo -e "${YELLOW}Para eliminarlos completamente:${NC}"
echo -e "  minikube ssh \"rm -rf /data/pv-datos\""
echo
