#!/bin/bash
# Ejercicio 4: Script de Inicializacion - download-config.sh
# Descripcion:
#   Script ejecutado por el Init Container config-setup.
#   Simula la descarga de configuracion desde un servidor remoto,
#   escribe el archivo /app/config/app.json y marca el setup como
#   completado creando /app/setup/complete.
#
# Conceptos clave:
#   - Init Container prepara archivos antes de que inicie la app principal
#   - Usa heredoc interno para crear JSON de configuracion
#   - El archivo /app/setup/complete es la "señal" de que el setup termino
#   - Montado como ConfigMap con defaultMode: 0755 para ser ejecutable
#
# Uso: montado en /setup/download-config.sh y ejecutado por el Init Container config-setup

# download-config.sh - Script de inicializacion
echo "📥 Downloading configuration..."
mkdir -p /app/config

# Simulate downloading config
cat > /app/config/app.json << 'CONFIG'
{
  "app_name": "My Application",
  "version": "1.0.0",
  "features": {
    "logging": true,
    "metrics": true,
    "debug": false
  },
  "database": {
    "pool_size": 10,
    "timeout": 30
  }
}
CONFIG

echo "✅ Configuration downloaded successfully"
echo "complete" > /app/setup/complete
