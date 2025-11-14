#!/bin/bash
# Cleanup RBAC Debugging resources

echo "🧹 Limpiando recursos RBAC..."

# Delete ServiceAccounts
kubectl delete sa sa-no-permissions sa-wrong-verbs sa-namespace-mismatch \
  sa-cluster-role-confusion sa-missing-apigroup sa-no-secrets sa-node-access \
  sa-pod-reader sa-cluster-viewer sa-deployment-manager --ignore-not-found

# Delete Roles
kubectl delete role role-wrong-verbs role-missing-apigroup role-full-pods \
  role-deployment-manager --ignore-not-found

# Delete RoleBindings
kubectl delete rolebinding rb-namespace-mismatch rb-cluster-role-confusion \
  rb-wrong-verbs rb-missing-apigroup rb-deployment-manager --ignore-not-found

# Delete ClusterRoles
kubectl delete clusterrole cr-node-access cr-cluster-viewer --ignore-not-found

# Delete ClusterRoleBindings
kubectl delete clusterrolebinding crb-cluster-viewer crb-node-access --ignore-not-found

echo "✅ Limpieza completada!"
