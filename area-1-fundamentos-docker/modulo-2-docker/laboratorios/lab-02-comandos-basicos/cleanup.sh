#!/bin/bash
echo "🧹 Limpiando recursos de Docker..."
echo ""
echo "Deteniendo contenedores activos..."
docker ps -q | xargs -r docker stop
echo ""
echo "Eliminando contenedores..."
docker ps -aq | xargs -r docker rm
echo ""
echo "Eliminando imágenes creadas en el lab..."
docker images | grep -E "mi-|lab-|test-" | awk '{print $3}' | xargs -r docker rmi 2>/dev/null || echo "  - Algunas imágenes en uso, ok"
echo ""
echo "✅ Limpieza básica completada"
echo ""
echo "Comandos adicionales si necesitas limpieza profunda:"
echo "  docker system prune -a     # Elimina TODO (cuidado)"
echo "  docker volume prune        # Elimina volúmenes huérfanos"
echo "  docker network prune       # Elimina redes no usadas"
