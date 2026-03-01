#!/bin/bash
# Ejercicio 1: Docker Setup Tradicional - docker-setup.sh
# Descripcion:
#   Script que demuestra el setup tradicional con Docker puro:
#   orquestacion manual de contenedores, esperas hardcodeadas,
#   multiples pasos sin manejo de errores automatico.
#   Se usa como COMPARACION con el enfoque de Init Containers.
#
# Conceptos clave:
#   - Orquestacion manual vs declarativa
#   - Problemas de esperas hardcodeadas (sleep 10)
#   - Complejidad de gestionar dependencias en Docker puro
#
# Uso: chmod +x docker-setup.sh && ./docker-setup.sh (solo para demostracion)

# docker-setup.sh - Docker Traditional Setup (Complex)
echo "🐳 Docker Traditional Setup (Complex)"

# 1. Create network
docker network create app-setup

# 2. Database setup
docker run -d --name db --network app-setup \
  -e POSTGRES_DB=myapp \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=pass \
  postgres:13

# 3. Wait for DB (manual orchestration)
echo "⏳ Waiting for database..."
sleep 10

# 4. Run migrations (separate container)
docker run --rm --network app-setup \
  -e DATABASE_URL=postgres://user:pass@db:5432/myapp \
  migrate/migrate:v4.15.1 \
  -path /migrations -database postgres://user:pass@db:5432/myapp up

# 5. Seed data (another container)
docker run --rm --network app-setup \
  -e DATABASE_URL=postgres://user:pass@db:5432/myapp \
  my-seed-image:v1

# 6. Download assets (yet another container)
docker run --rm -v $(pwd)/assets:/output \
  busybox wget -O /output/app.js https://cdn.example.com/app.js

# 7. Finally start main app
docker run -d --name app --network app-setup \
  -v $(pwd)/assets:/app/static \
  -e DATABASE_URL=postgres://user:pass@db:5432/myapp \
  my-app:v1

echo "❌ Problems with this approach:"
echo "├─ Manual orchestration"
echo "├─ Complex dependency management"
echo "├─ Multiple network/volume setups"
echo "└─ Hard to reproduce consistently"
