#!/bin/bash

# 🎨 Script para Integración de Diagramas Draw.io en Curso Kubernetes
# Automatiza la conversión de .drawio a SVG y actualización de documentación

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
DIAGRAMS_DIR="./assets/diagrams"
MODULES_DIR="."
DRAWIO_CLI="drawio" # Requiere draw.io CLI instalado

echo -e "${BLUE}🎨 Kubernetes Course - Draw.io Integration Tool${NC}"
echo -e "${BLUE}=================================================${NC}"

# Función para instalar draw.io CLI si no existe
check_drawio_cli() {
    if ! command -v $DRAWIO_CLI &> /dev/null; then
        echo -e "${YELLOW}⚠️  Draw.io CLI no encontrado. Instalando...${NC}"
        
        # Para sistemas Linux/macOS
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo -e "${BLUE}📦 Instalando para Linux...${NC}"
            npm install -g @marp-team/marp-cli
            wget https://github.com/jgraph/drawio-desktop/releases/download/v21.6.8/drawio-amd64-21.6.8.deb
            sudo dpkg -i drawio-amd64-21.6.8.deb
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            echo -e "${BLUE}📦 Instalando para macOS...${NC}"
            brew install --cask drawio
        else
            echo -e "${RED}❌ OS no soportado. Instala Draw.io CLI manualmente.${NC}"
            echo -e "${YELLOW}💡 Instrucciones: https://github.com/jgraph/drawio-desktop${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ Draw.io CLI encontrado${NC}"
    fi
}

# Función para convertir .drawio a SVG
convert_drawio_to_svg() {
    local drawio_file="$1"
    local svg_file="${drawio_file%.drawio}.svg"
    
    echo -e "${BLUE}🔄 Convirtiendo: $(basename "$drawio_file")${NC}"
    
    if $DRAWIO_CLI --export --format svg --output "$svg_file" "$drawio_file"; then
        echo -e "${GREEN}✅ Generado: $(basename "$svg_file")${NC}"
        return 0
    else
        echo -e "${RED}❌ Error convirtiendo: $(basename "$drawio_file")${NC}"
        return 1
    fi
}

# Función para procesar todos los diagramas
process_all_diagrams() {
    echo -e "${BLUE}🔍 Buscando archivos .drawio...${NC}"
    
    local count=0
    local success=0
    
    find "$DIAGRAMS_DIR" -name "*.drawio" -type f | while read -r file; do
        ((count++))
        if convert_drawio_to_svg "$file"; then
            ((success++))
        fi
    done
    
    echo -e "${GREEN}📊 Procesados: $success/$count diagramas${NC}"
}

# Función para generar referencias markdown
generate_markdown_refs() {
    echo -e "${BLUE}📝 Generando referencias Markdown...${NC}"
    
    cat > "$DIAGRAMS_DIR/REFERENCES.md" << EOF
# 🎨 Referencias de Diagramas Draw.io

## 📁 Módulo 01 - Introducción

### Docker vs Kubernetes Evolution
\`\`\`markdown
![Docker vs Kubernetes](./assets/diagrams/01-introduccion/docker-vs-kubernetes.svg)
\`\`\`

### Traditional vs K8s Resources Efficiency  
\`\`\`markdown
![Resources Efficiency](./assets/diagrams/01-introduccion/traditional-vs-k8s-resources.svg)
\`\`\`

### Kubernetes Abstraction Layer
\`\`\`markdown
![Kubernetes Abstraction](./assets/diagrams/01-introduccion/kubernetes-abstraction.svg)
\`\`\`

### Roles Separation Diagram
\`\`\`markdown
![Roles Separation](./assets/diagrams/01-introduccion/roles-separation.svg)
\`\`\`

---

## 🔗 Enlaces para Edición

- **[🎨 Editar Docker vs Kubernetes](https://app.diagrams.net/?url=https://raw.githubusercontent.com/tu-repo/assets/diagrams/01-introduccion/docker-vs-kubernetes.drawio)**
- **[🎨 Editar Resources Efficiency](https://app.diagrams.net/?url=https://raw.githubusercontent.com/tu-repo/assets/diagrams/01-introduccion/traditional-vs-k8s-resources.drawio)**

---

## 📋 Instrucciones de Uso

1. **Para ver diagramas**: Los SVG se muestran automáticamente en GitHub
2. **Para editar**: Haz clic en los enlaces de edición arriba
3. **Para actualizar**: Ejecuta \`./scripts/update-diagrams.sh\` después de editar

EOF

    echo -e "${GREEN}✅ Referencias generadas en: $DIAGRAMS_DIR/REFERENCES.md${NC}"
}

# Función para actualizar README principal
update_main_readme() {
    local readme_file="$MODULES_DIR/modulo-01-introduccion-kubernetes/README.md"
    
    if [[ -f "$readme_file" ]]; then
        echo -e "${BLUE}📝 Actualizando README principal...${NC}"
        
        # Crear backup
        cp "$readme_file" "$readme_file.backup"
        
        # Agregar sección de diagramas si no existe
        if ! grep -q "## 🎨 Diagramas Interactivos" "$readme_file"; then
            cat >> "$readme_file" << EOF

---

## 🎨 Diagramas Interactivos

### **📊 Evolución: Docker → Kubernetes**
![Docker vs Kubernetes Evolution](../assets/diagrams/01-introduccion/docker-vs-kubernetes.svg)

### **⚡ Eficiencia de Recursos: Tradicional vs Kubernetes**
![Resources Efficiency Comparison](../assets/diagrams/01-introduccion/traditional-vs-k8s-resources.svg)

### **🔄 Enlaces para Editar Diagramas:**
- **[🎨 Editar Evolución Docker vs K8s](https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/tu-repo/main/area-2-arquitectura-kubernetes/assets/diagrams/01-introduccion/docker-vs-kubernetes.drawio)**
- **[🎨 Editar Eficiencia de Recursos](https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/tu-repo/main/area-2-arquitectura-kubernetes/assets/diagrams/01-introduccion/traditional-vs-k8s-resources.drawio)**

> 💡 **Tip**: Los diagramas son editables directamente desde GitHub. Haz clic en los enlaces para modificarlos.

EOF
            echo -e "${GREEN}✅ Sección de diagramas agregada al README${NC}"
        else
            echo -e "${YELLOW}⚠️  Sección de diagramas ya existe en README${NC}"
        fi
    else
        echo -e "${RED}❌ README no encontrado: $readme_file${NC}"
    fi
}

# Función para validar estructura
validate_structure() {
    echo -e "${BLUE}🔍 Validando estructura de directorios...${NC}"
    
    local required_dirs=(
        "$DIAGRAMS_DIR/01-introduccion"
        "$DIAGRAMS_DIR/templates"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo -e "${GREEN}✅ $dir${NC}"
        else
            echo -e "${RED}❌ $dir${NC}"
            mkdir -p "$dir"
            echo -e "${YELLOW}📁 Directorio creado: $dir${NC}"
        fi
    done
}

# Función para mostrar estadísticas
show_stats() {
    echo -e "${BLUE}📊 Estadísticas:${NC}"
    echo -e "${YELLOW}📁 Directorios de diagramas:${NC} $(find "$DIAGRAMS_DIR" -type d | wc -l)"
    echo -e "${YELLOW}🎨 Archivos .drawio:${NC} $(find "$DIAGRAMS_DIR" -name "*.drawio" | wc -l)"
    echo -e "${YELLOW}🖼️  Archivos .svg:${NC} $(find "$DIAGRAMS_DIR" -name "*.svg" | wc -l)"
    echo -e "${YELLOW}📝 READMEs:${NC} $(find "$DIAGRAMS_DIR" -name "README.md" | wc -l)"
}

# Función de ayuda
show_help() {
    echo -e "${BLUE}🎨 Kubernetes Draw.io Integration Tool${NC}"
    echo -e "${BLUE}===================================${NC}"
    echo ""
    echo -e "${YELLOW}COMANDOS:${NC}"
    echo -e "  ${GREEN}./update-diagrams.sh convert${NC}     - Convierte todos los .drawio a SVG"
    echo -e "  ${GREEN}./update-diagrams.sh generate${NC}    - Genera referencias Markdown"
    echo -e "  ${GREEN}./update-diagrams.sh update${NC}      - Actualiza README principal"
    echo -e "  ${GREEN}./update-diagrams.sh validate${NC}    - Valida estructura de directorios"
    echo -e "  ${GREEN}./update-diagrams.sh stats${NC}       - Muestra estadísticas"
    echo -e "  ${GREEN}./update-diagrams.sh all${NC}         - Ejecuta todo el proceso completo"
    echo -e "  ${GREEN}./update-diagrams.sh help${NC}        - Muestra esta ayuda"
    echo ""
    echo -e "${YELLOW}EJEMPLOS:${NC}"
    echo -e "  ${BLUE}# Proceso completo automático${NC}"
    echo -e "  ./update-diagrams.sh all"
    echo ""
    echo -e "  ${BLUE}# Solo convertir diagramas${NC}"
    echo -e "  ./update-diagrams.sh convert"
}

# Función principal
main() {
    case "${1:-all}" in
        "convert")
            validate_structure
            check_drawio_cli
            process_all_diagrams
            ;;
        "generate")
            generate_markdown_refs
            ;;
        "update")
            update_main_readme
            ;;
        "validate")
            validate_structure
            ;;
        "stats")
            show_stats
            ;;
        "all")
            validate_structure
            check_drawio_cli
            process_all_diagrams
            generate_markdown_refs
            update_main_readme
            show_stats
            echo -e "${GREEN}🎉 ¡Proceso completo terminado!${NC}"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${RED}❌ Comando no reconocido: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"