#!/bin/bash
# Limpieza completa del Laboratorio Integral AKS
# Uso: bash cleanup.sh
#
# Descripcion:
#   Elimina TODOS los recursos creados durante el laboratorio:
#   - Namespaces (tienda-web, tienda-api, tienda-db, stress-test)
#   - Stack de monitoreo (Prometheus + Grafana via Helm)
#   - Namespace monitoring
#   - Pods temporales de testing
#
#   Al eliminar un namespace, Kubernetes borra automaticamente
#   todos los recursos dentro de el (Pods, Services, Secrets, etc.)
#
#   NOTA: El cluster AKS NO se elimina. Solo los recursos del lab.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}============================================${NC}"
echo -e "${YELLOW}  Limpieza del Laboratorio Integral AKS     ${NC}"
echo -e "${YELLOW}============================================${NC}"
echo ""

# Funcion para eliminar un recurso de forma segura
delete_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    if [ -n "$namespace" ]; then
        if kubectl get $resource_type $resource_name -n $namespace &> /dev/null; then
            kubectl delete $resource_type $resource_name -n $namespace --ignore-not-found=true
            echo -e "  ${GREEN}$resource_type/$resource_name eliminado de $namespace${NC}"
        else
            echo -e "  ${YELLOW}$resource_type/$resource_name no existe en $namespace (skip)${NC}"
        fi
    else
        if kubectl get $resource_type $resource_name &> /dev/null; then
            kubectl delete $resource_type $resource_name --ignore-not-found=true
            echo -e "  ${GREEN}$resource_type/$resource_name eliminado${NC}"
        else
            echo -e "  ${YELLOW}$resource_type/$resource_name no existe (skip)${NC}"
        fi
    fi
}

# --- Paso 1: Desinstalar Prometheus via Helm ---
echo -e "${YELLOW}[1/4] Desinstalando Prometheus + Grafana (Helm)...${NC}"
if helm list -n monitoring 2>/dev/null | grep -q prometheus; then
    helm uninstall prometheus -n monitoring --wait 2>/dev/null
    echo -e "  ${GREEN}Helm release 'prometheus' desinstalado${NC}"
else
    echo -e "  ${YELLOW}Helm release 'prometheus' no encontrado (skip)${NC}"
fi

# Limpiar CRDs de Prometheus (opcional, pueden tardar)
echo "  Limpiando CRDs de Prometheus..."
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com --ignore-not-found=true 2>/dev/null
kubectl delete crd alertmanagers.monitoring.coreos.com --ignore-not-found=true 2>/dev/null
kubectl delete crd podmonitors.monitoring.coreos.com --ignore-not-found=true 2>/dev/null
kubectl delete crd probes.monitoring.coreos.com --ignore-not-found=true 2>/dev/null
kubectl delete crd prometheusagents.monitoring.coreos.com --ignore-not-found=true 2>/dev/null
kubectl delete crd prometheuses.monitoring.coreos.com --ignore-not-found=true 2>/dev/null
kubectl delete crd prometheusrules.monitoring.coreos.com --ignore-not-found=true 2>/dev/null
kubectl delete crd scrapeconfigs.monitoring.coreos.com --ignore-not-found=true 2>/dev/null
kubectl delete crd servicemonitors.monitoring.coreos.com --ignore-not-found=true 2>/dev/null
kubectl delete crd thanosrulers.monitoring.coreos.com --ignore-not-found=true 2>/dev/null
echo -e "  ${GREEN}CRDs de Prometheus limpiados${NC}"
echo ""

# --- Paso 2: Eliminar Pods temporales de testing ---
echo -e "${YELLOW}[2/4] Eliminando Pods temporales...${NC}"
kubectl delete pod test-connectivity --ignore-not-found=true -n tienda-web 2>/dev/null
kubectl delete pod test-redis --ignore-not-found=true -n tienda-api 2>/dev/null
kubectl delete pod debug --ignore-not-found=true -n tienda-web 2>/dev/null
kubectl delete pod load-test --ignore-not-found=true 2>/dev/null
echo -e "  ${GREEN}Pods temporales limpiados${NC}"
echo ""

# --- Paso 3: Eliminar namespaces (borra TODO dentro de ellos) ---
echo -e "${YELLOW}[3/4] Eliminando namespaces del laboratorio...${NC}"
echo "  (Esto puede tardar 1-2 minutos por namespace...)"

for NS in tienda-web tienda-api tienda-db stress-test monitoring; do
    if kubectl get namespace $NS &> /dev/null; then
        kubectl delete namespace $NS --ignore-not-found=true &
        echo -e "  ${GREEN}Namespace '$NS' marcado para eliminacion${NC}"
    else
        echo -e "  ${YELLOW}Namespace '$NS' no existe (skip)${NC}"
    fi
done

# Esperar a que los namespaces se eliminen
echo ""
echo "  Esperando a que los namespaces se eliminen..."
for NS in tienda-web tienda-api tienda-db stress-test monitoring; do
    while kubectl get namespace $NS &> /dev/null 2>&1; do
        sleep 2
    done
done
echo -e "  ${GREEN}Todos los namespaces eliminados${NC}"
echo ""

# --- Paso 4: Verificacion final ---
echo -e "${YELLOW}[4/4] Verificacion final...${NC}"
echo ""
echo "  Namespaces restantes en el cluster:"
kubectl get namespaces
echo ""
echo "  Nodos del cluster:"
kubectl get nodes
echo ""

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Limpieza completada!                      ${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "  El cluster AKS sigue activo."
echo -e "  Si el cluster autoescalo, los nodos extra se eliminaran"
echo -e "  automaticamente en ~10 minutos al no haber carga."
echo ""
echo -e "  Para eliminar el cluster completamente:"
echo -e "  az aks delete --resource-group <RG> --name <CLUSTER> --yes"
