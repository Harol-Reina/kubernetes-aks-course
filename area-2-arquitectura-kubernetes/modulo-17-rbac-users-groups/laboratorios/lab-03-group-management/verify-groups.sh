#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
PASSED=0; FAILED=0

test_pass() { echo -e "${GREEN}✓${NC} $1"; ((PASSED++)); }
test_fail() { echo -e "${RED}✗${NC} $1"; ((FAILED++)); }

echo "========== Verification: Group-based RBAC =========="

# Test: RoleBindings usan kind: Group
if kubectl get rolebinding developers-binding -n dev -o jsonpath='{.subjects[0].kind}' | grep -q "Group"; then
    test_pass "RoleBinding usa kind: Group"
else
    test_fail "RoleBinding NO usa kind: Group"
fi

# Test: Alice y Bob (developers) tienen mismos permisos
ORIG_CTX=$(kubectl config current-context)

kubectl config use-context alice@kubernetes &>/dev/null
ALICE_CAN=$(kubectl auth can-i get pods -n dev 2>/dev/null && echo "yes" || echo "no")

kubectl config use-context bob@kubernetes &>/dev/null
BOB_CAN=$(kubectl auth can-i get pods -n dev 2>/dev/null && echo "yes" || echo "no")

if [ "$ALICE_CAN" == "yes" ] && [ "$BOB_CAN" == "yes" ]; then
    test_pass "Alice y Bob (mismo grupo) tienen mismos permisos"
else
    test_fail "Alice y Bob NO tienen mismos permisos"
fi

# Test: Alice NO puede acceder a test (de testers)
kubectl config use-context alice@kubernetes &>/dev/null
if ! kubectl get pods -n test &>/dev/null; then
    test_pass "Alice NO puede acceder a namespace test (correcto)"
else
    test_fail "Alice PUEDE acceder a test (aislamiento roto)"
fi

# Test: Eve y Frank (admins) tienen permisos cluster-wide
kubectl config use-context eve@kubernetes &>/dev/null
if kubectl get namespaces &>/dev/null; then
    test_pass "Eve (admins) puede ver namespaces"
else
    test_fail "Eve NO puede ver namespaces"
fi

kubectl config use-context ${ORIG_CTX} &>/dev/null

echo ""
echo "========== Resumen =========="
echo -e "Pasados: ${GREEN}${PASSED}${NC}"
echo -e "Fallidos: ${RED}${FAILED}${NC}"

[ $FAILED -eq 0 ] && echo -e "${GREEN}✓ Group-based RBAC OK${NC}" || echo -e "${RED}✗ Problemas detectados${NC}"
exit $FAILED
