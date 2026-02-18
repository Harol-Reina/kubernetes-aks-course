#!/bin/bash

# cleanup.sh - Lab 01: Crear ServiceAccounts

echo "🧹 Limpiando recursos del Lab 01..."

# ServiceAccounts
kubectl delete sa mi-serviceaccount 2>/dev/null
kubectl delete sa app-sa backend-sa 2>/dev/null
kubectl delete sa custom-sa 2>/dev/null

# Roles y RoleBindings
kubectl delete role pod-reader 2>/dev/null
kubectl delete rolebinding read-pods 2>/dev/null

# Pods y Deployments
kubectl delete pod nginx-with-sa 2>/dev/null
kubectl delete deployment app-with-sa 2>/dev/null

echo "✅ Limpieza completada"
kubectl get sa
