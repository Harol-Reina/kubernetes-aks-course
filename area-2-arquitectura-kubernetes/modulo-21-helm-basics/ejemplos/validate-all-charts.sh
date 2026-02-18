#!/bin/bash

# Validar todos los Helm charts de ejemplos

echo "🔍 Validando todos los Helm Charts..."
echo ""

CHARTS=("basic-chart" "multi-tier-app" "helm-hooks" "chart-dependencies" "advanced-templates")
TOTAL_ERRORS=0

for chart in "${CHARTS[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Validando: $chart"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ ! -d "$chart" ]; then
        echo "❌ Directorio no encontrado: $chart"
        ((TOTAL_ERRORS++))
        continue
    fi
    
    # Verificar archivos requeridos
    REQUIRED_FILES=("Chart.yaml" "values.yaml" "templates")
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -e "$chart/$file" ]; then
            echo "  ✅ $file existe"
        else
            echo "  ❌ $file NO encontrado"
            ((TOTAL_ERRORS++))
        fi
    done
    
    # Contar templates
    TEMPLATE_COUNT=$(ls -1 "$chart/templates/"*.yaml 2>/dev/null | wc -l)
    echo "  📄 Templates: $TEMPLATE_COUNT archivos"
    
    # Validar YAML con Python
    if python3 -c "import yaml; yaml.safe_load(open('$chart/Chart.yaml'))" 2>/dev/null; then
        echo "  ✅ Chart.yaml válido"
    else
        echo "  ❌ Chart.yaml inválido"
        ((TOTAL_ERRORS++))
    fi
    
    if python3 -c "import yaml; yaml.safe_load(open('$chart/values.yaml'))" 2>/dev/null; then
        echo "  ✅ values.yaml válido"
    else
        echo "  ❌ values.yaml inválido"
        ((TOTAL_ERRORS++))
    fi
    
    # Verificar que templates tengan sintaxis Go
    HAS_TEMPLATES=$(grep -r "{{" "$chart/templates/" 2>/dev/null | wc -l)
    if [ $HAS_TEMPLATES -gt 0 ]; then
        echo "  ✅ Templates usan sintaxis Go ($HAS_TEMPLATES ocurrencias)"
    else
        echo "  ⚠️  Templates no usan sintaxis Go"
    fi
    
    # Verificar README existe
    if [ -f "$chart/README.md" ]; then
        echo "  ✅ README.md existe"
    else
        echo "  ⚠️  README.md no encontrado"
    fi
    
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESUMEN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Charts validados: ${#CHARTS[@]}"

if [ $TOTAL_ERRORS -eq 0 ]; then
    echo "✅ Todos los charts son válidos"
    echo ""
    echo "🚀 Comandos sugeridos:"
    echo ""
    for chart in "${CHARTS[@]}"; do
        echo "  # $chart"
        echo "  cd $chart"
        echo "  helm template test-release ."
        echo "  helm install my-$chart ."
        echo "  cd .."
        echo ""
    done
    exit 0
else
    echo "❌ Se encontraron $TOTAL_ERRORS error(es)"
    exit 1
fi
