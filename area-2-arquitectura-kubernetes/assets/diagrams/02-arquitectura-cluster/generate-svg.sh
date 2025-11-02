#!/bin/bash

# Script para convertir diagramas Draw.io a SVG para el Módulo 02
# Arquitectura de Cluster Kubernetes

echo "🎨 Generando diagramas SVG para Módulo 02 - Arquitectura de Cluster..."

# Crear directorio para SVGs si no existe
mkdir -p /media/Data/Source/Courses/K8S/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/svg

# URLs de los diagramas en Draw.io (para conversión)
BASE_URL="https://app.diagrams.net"

# Lista de diagramas a convertir
declare -A DIAGRAMS=(
    ["cluster-overview"]="Vista general del cluster completo"
    ["control-plane-detailed"]="Arquitectura detallada del Control Plane"
    ["worker-nodes-detailed"]="Arquitectura detallada de Worker Nodes"
)

echo "📋 Diagramas a procesar:"
for diagram in "${!DIAGRAMS[@]}"; do
    echo "  - $diagram: ${DIAGRAMS[$diagram]}"
done

echo ""
echo "🔄 Procesando diagramas..."

for diagram in "${!DIAGRAMS[@]}"; do
    echo "  📊 Procesando: $diagram"
    
    # Archivo fuente
    SOURCE_FILE="/media/Data/Source/Courses/K8S/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/${diagram}.drawio"
    
    # Archivo destino SVG
    SVG_FILE="/media/Data/Source/Courses/K8S/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/svg/${diagram}.svg"
    
    if [ -f "$SOURCE_FILE" ]; then
        echo "    ✅ Archivo fuente encontrado: $SOURCE_FILE"
        echo "    🔄 Generando SVG: $SVG_FILE"
        
        # Para la conversión real, se usaría el CLI de Draw.io o API
        # Por ahora, crear un placeholder SVG profesional
        cat > "$SVG_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg width="1600" height="1200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#E3F2FD;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#BBDEFB;stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <!-- Background -->
  <rect width="100%" height="100%" fill="url(#bgGradient)"/>
  
  <!-- Title -->
  <text x="800" y="60" text-anchor="middle" font-family="Arial, sans-serif" font-size="28" font-weight="bold" fill="#1976D2">
    🚀 Kubernetes $(echo $diagram | tr '-' ' ' | tr '[:lower:]' '[:upper:]')
  </text>
  
  <!-- Subtitle -->
  <text x="800" y="100" text-anchor="middle" font-family="Arial, sans-serif" font-size="16" fill="#424242">
    ${DIAGRAMS[$diagram]}
  </text>
  
  <!-- Instructions -->
  <text x="800" y="600" text-anchor="middle" font-family="Arial, sans-serif" font-size="18" font-weight="bold" fill="#1976D2">
    📖 Para ver el diagrama completo e interactivo:
  </text>
  
  <!-- Draw.io Link -->
  <text x="800" y="650" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" fill="#1976D2" text-decoration="underline">
    🔗 Abrir en Draw.io: https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/${diagram}.drawio
  </text>
  
  <!-- Professional border -->
  <rect x="50" y="50" width="1500" height="1100" fill="none" stroke="#1976D2" stroke-width="3" rx="20"/>
  
  <!-- Professional diagram placeholder -->
  <g transform="translate(100, 150)">
    <!-- Control Plane representation -->
    <rect x="0" y="0" width="600" height="300" fill="#E3F2FD" stroke="#1976D2" stroke-width="2" rx="15"/>
    <text x="300" y="30" text-anchor="middle" font-family="Arial, sans-serif" font-size="16" font-weight="bold" fill="#1976D2">
      🎛️ CONTROL PLANE
    </text>
    
    <!-- Worker Nodes representation -->
    <rect x="700" y="0" width="700" height="300" fill="#E8F5E8" stroke="#388E3C" stroke-width="2" rx="15"/>
    <text x="1050" y="30" text-anchor="middle" font-family="Arial, sans-serif" font-size="16" font-weight="bold" fill="#388E3C">
      💪 WORKER NODES
    </text>
    
    <!-- External Access representation -->
    <rect x="0" y="400" width="1400" height="150" fill="#F3E5F5" stroke="#7B1FA2" stroke-width="2" rx="15"/>
    <text x="700" y="430" text-anchor="middle" font-family="Arial, sans-serif" font-size="16" font-weight="bold" fill="#7B1FA2">
      🌐 EXTERNAL ACCESS
    </text>
  </g>
  
  <!-- Footer -->
  <text x="800" y="1150" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#666">
    📚 Kubernetes AKS Course - Módulo 02: Arquitectura de Cluster
  </text>
</svg>
EOF
        
        echo "    ✅ SVG generado exitosamente"
    else
        echo "    ❌ Error: Archivo fuente no encontrado"
    fi
    echo ""
done

echo "🎉 ¡Proceso completado!"
echo ""
echo "📁 Archivos SVG generados en:"
echo "   /media/Data/Source/Courses/K8S/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/svg/"
echo ""
echo "🔗 URLs para usar en README:"
for diagram in "${!DIAGRAMS[@]}"; do
    echo "  - $diagram: https://raw.githubusercontent.com/Harol-Reina/kubernetes-aks-course/main/area-2-arquitectura-kubernetes/assets/diagrams/02-arquitectura-cluster/svg/${diagram}.svg"
done
echo ""
echo "📖 Para editar los diagramas, usa Draw.io con los archivos .drawio"
echo "💡 Los diagramas se pueden exportar manualmente desde Draw.io como SVG para obtener la versión final"