#!/bin/bash
set -euo pipefail

NAMESPACES=("dev" "test" "prod")
USERS=("dev-user" "test-user" "prod-admin")

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
PASSED=0; FAILED=0

test_pass() { echo -e "${GREEN}✓${NC} $1"; ((PASSED++)); }
test_fail() { echo -e "${RED}✗${NC} $1"; ((FAILED++)); }

echo "========== Verification: Namespace Isolation =========="

# Test: Namespaces existen
for ns in "${NAMESPACES[@]}"; do
    if kubectl get ns $ns &>/dev/null; then
        test_pass "Namespace $ns existe"
    else
        test_fail "Namespace $ns NO existe"
    fi
done

# Test: Roles existen
if kubectl get role pod-reader -n dev &>/dev/null; then test_pass "Role pod-reader existe"; else test_fail "Role pod-reader falta"; fi
if kubectl get role pod-writer -n test &>/dev/null; then test_pass "Role pod-writer existe"; else test_fail "Role pod-writer falta"; fi
if kubectl get role namespace-admin -n prod &>/dev/null; then test_pass "Role namespace-admin existe"; else test_fail "Role namespace-admin falta"; fi

# Test: RoleBindings existen
for i in "${!USERS[@]}"; do
    user="${USERS[$i]}"
    ns="${NAMESPACES[$i]}"
    if kubectl get rolebinding ${user}-binding -n $ns &>/dev/null; then
        test_pass "RoleBinding para $user existe"
    else
        test_fail "RoleBinding para $user falta"
    fi
done

# Test: Aislamiento (dev-user NO puede ver test)
ORIG_CTX=$(kubectl config current-context)
kubectl config use-context dev-user@kubernetes &>/dev/null
if ! kubectl get pods -n test &>/dev/null; then
    test_pass "dev-user NO puede ver namespace test (correcto)"
else
    test_fail "dev-user PUEDE ver test (aislamiento roto)"
fi

# Test: test-user NO puede ver prod
kubectl config use-context test-user@kubernetes &>/dev/null
if ! kubectl get pods -n prod &>/dev/null; then
    test_pass "test-user NO puede ver namespace prod (correcto)"
else
    test_fail "test-user PUEDE ver prod (aislamiento roto)"
fi

# Test: Permisos diferenciados
kubectl config use-context dev-user@kubernetes &>/dev/null
if ! kubectl auth can-i create pods -n dev 2>/dev/null; then
    test_pass "dev-user NO puede crear pods (correcto)"
else
    test_fail "dev-user PUEDE crear pods (permisos excesivos)"
fi

kubectl config use-context test-user@kubernetes &>/dev/null
if kubectl auth can-i create pods -n test 2>/dev/null; then
    test_pass "test-user PUEDE crear pods (correcto)"
else
    test_fail "test-user NO puede crear pods"
fi

kubectl config use-context ${ORIG_CTX} &>/dev/null

echo ""
echo "========== Resumen =========="
echo -e "Pasados: ${GREEN}${PASSED}${NC}"
echo -e "Fallidos: ${RED}${FAILED}${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Aislamiento de namespaces configurado correctamente${NC}"
    exit 0
else
    echo -e "${RED}✗ Problemas detectados${NC}"
    exit 1
fi
