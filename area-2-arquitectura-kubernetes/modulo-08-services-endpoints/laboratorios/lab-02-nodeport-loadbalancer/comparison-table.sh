#!/bin/bash
# comparison-table.sh - Tabla comparativa de tipos de Service

echo "📊 TABLA COMPARATIVA: Tipos de Service en Kubernetes"
echo ""
printf "%-20s %-15s %-20s %-30s\n" "TIPO" "ALCANCE" "PUERTO" "USO TÍPICO"
echo "=================================================================================="
printf "%-20s %-15s %-20s %-30s\n" "ClusterIP" "Interno" "Cluster IP" "Backend, DBs internas"
printf "%-20s %-15s %-20s %-30s\n" "NodePort" "Externo" "30000-32767" "Testing, desarrollo"
printf "%-20s %-15s %-20s %-30s\n" "LoadBalancer" "Externo" "Asignado por Cloud" "Apps públicas, producción"
printf "%-20s %-15s %-20s %-30s\n" "ExternalName" "Externo" "DNS CNAME" "Migración, servicios externos"
echo ""
