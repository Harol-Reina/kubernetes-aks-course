#!/bin/bash
# blue-green-deploy.sh - Script automatizado de Blue-Green deployment

set -e

APP_NAME=${1:-myapp}
NEW_VERSION=${2:-green}
OLD_VERSION=${3:-blue}
REPLICAS=${4:-3}
IMAGE=${5:-nginx:latest}
NAMESPACE=${6:-lab-estrategias}

echo "🚀 Blue-Green Deployment"
echo "App: $APP_NAME"
echo "Old version: $OLD_VERSION"
echo "New version: $NEW_VERSION"
echo ""

# 1. Deploy nueva versión (Green)
echo "📦 Desplegando versión $NEW_VERSION..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME-$NEW_VERSION
  namespace: $NAMESPACE
spec:
  replicas: $REPLICAS
  selector:
    matchLabels:
      app: $APP_NAME
      version: $NEW_VERSION
  template:
    metadata:
      labels:
        app: $APP_NAME
        version: $NEW_VERSION
    spec:
      containers:
      - name: app
        image: $IMAGE
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

# 2. Esperar que nueva versión esté Ready
echo "⏳ Esperando que $NEW_VERSION esté listo..."
kubectl wait --for=condition=available deployment/$APP_NAME-$NEW_VERSION -n $NAMESPACE --timeout=120s
echo "✅ $NEW_VERSION está listo"

# 3. Crear servicio de test
echo "🧪 Creando servicio de test..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: $APP_NAME-$NEW_VERSION-test
  namespace: $NAMESPACE
spec:
  selector:
    app: $APP_NAME
    version: $NEW_VERSION
  ports:
  - port: 80
    targetPort: 80
EOF

# 4. Confirmar switch
echo ""
echo "🧪 Prueba la nueva versión en: kubectl port-forward svc/$APP_NAME-$NEW_VERSION-test 8080:80 -n $NAMESPACE"
echo ""
read -p "¿Cambiar tráfico de producción a $NEW_VERSION? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelado"
    exit 1
fi

# 5. Switch de tráfico
echo "🔀 Cambiando tráfico a $NEW_VERSION..."
kubectl patch service $APP_NAME-production -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"version\":\"$NEW_VERSION\"}}}"
echo "✅ Tráfico cambiado a $NEW_VERSION"

# 6. Confirmar eliminación de versión antigua
echo ""
read -p "¿Eliminar deployment $OLD_VERSION? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete deployment $APP_NAME-$OLD_VERSION -n $NAMESPACE
    echo "✅ Deployment $OLD_VERSION eliminado"
fi

echo ""
echo "🎉 Blue-Green deployment completado"
