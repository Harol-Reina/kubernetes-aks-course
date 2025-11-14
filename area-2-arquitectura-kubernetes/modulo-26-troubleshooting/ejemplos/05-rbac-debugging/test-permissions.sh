#!/bin/bash
# Test RBAC permissions for all ServiceAccounts

echo "🔐 Testing RBAC permissions..."
echo ""

# Test each SA
SAs=(
  "sa-no-permissions"
  "sa-wrong-verbs"
  "sa-namespace-mismatch"
  "sa-cluster-role-confusion"
  "sa-missing-apigroup"
  "sa-no-secrets"
  "sa-node-access"
  "sa-pod-reader"
  "sa-cluster-viewer"
  "sa-deployment-manager"
)

for sa in "${SAs[@]}"; do
  echo "Testing: $sa"
  echo "  - Can list pods: $(kubectl auth can-i list pods --as=system:serviceaccount:default:$sa)"
  echo "  - Can create pods: $(kubectl auth can-i create pods --as=system:serviceaccount:default:$sa)"
  echo "  - Can get secrets: $(kubectl auth can-i get secrets --as=system:serviceaccount:default:$sa)"
  echo ""
done

echo "✅ Test completado!"
