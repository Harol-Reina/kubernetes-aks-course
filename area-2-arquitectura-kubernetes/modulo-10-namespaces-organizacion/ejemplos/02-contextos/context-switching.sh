#!/bin/bash
# =============================================================================
# Script: Context Switching Helper
# =============================================================================
# Descripción:
#   Script de utilidad para gestionar contextos y namespaces de Kubernetes
#   de forma interactiva y segura.
#
# Funcionalidades:
#   1. Listar y cambiar contextos
#   2. Listar y cambiar namespaces
#   3. Verificar contexto/namespace actual
#   4. Crear contextos rápidamente
#   5. Seguridad: confirmación para contextos de producción
#
# Requisitos:
#   - kubectl
#   - fzf (opcional, para búsqueda interactiva)
#
# Uso:
#   ./context-switching.sh
#   chmod +x context-switching.sh
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURACIÓN
# =============================================================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Prefijos de contextos de producción (requieren confirmación)
PROD_PREFIXES=("prod" "production" "prd")

# =============================================================================
# FUNCIONES AUXILIARES
# =============================================================================

# Imprimir con color
print_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

print_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

# Verificar si un contexto es de producción
is_production_context() {
    local context="$1"
    for prefix in "${PROD_PREFIXES[@]}"; do
        if [[ "$context" == *"$prefix"* ]]; then
            return 0
        fi
    done
    return 1
}

# Confirmar acción
confirm() {
    local message="$1"
    read -p "$(echo -e ${YELLOW}${message}${NC}) [y/N]: " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Verificar dependencias
check_dependencies() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl no está instalado"
        exit 1
    fi
}

# =============================================================================
# FUNCIONES PRINCIPALES
# =============================================================================

# Mostrar contexto y namespace actual
show_current() {
    local current_context
    local current_namespace
    
    current_context=$(kubectl config current-context 2>/dev/null || echo "none")
    current_namespace=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null || echo "default")
    
    echo ""
    print_info "Configuración actual:"
    echo "  Contexto:   $current_context"
    echo "  Namespace:  $current_namespace"
    echo ""
    
    # Mostrar información del clúster
    if [[ "$current_context" != "none" ]]; then
        local cluster_info
        cluster_info=$(kubectl cluster-info 2>/dev/null | head -n 1)
        echo "  $cluster_info"
        echo ""
    fi
}

# Listar contextos
list_contexts() {
    print_info "Contextos disponibles:"
    kubectl config get-contexts
}

# Cambiar de contexto
switch_context() {
    local target_context="$1"
    
    # Verificar que el contexto existe
    if ! kubectl config get-contexts "$target_context" &>/dev/null; then
        print_error "Contexto '$target_context' no existe"
        return 1
    fi
    
    # Confirmar si es producción
    if is_production_context "$target_context"; then
        print_warning "¡ATENCIÓN! Vas a cambiar a un contexto de PRODUCCIÓN: $target_context"
        if ! confirm "¿Estás seguro?"; then
            print_info "Cambio de contexto cancelado"
            return 0
        fi
    fi
    
    # Cambiar contexto
    kubectl config use-context "$target_context"
    print_success "Cambiado a contexto: $target_context"
    
    # Mostrar información actualizada
    show_current
}

# Listar namespaces
list_namespaces() {
    print_info "Namespaces disponibles en el contexto actual:"
    kubectl get namespaces -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,AGE:.metadata.creationTimestamp
}

# Cambiar de namespace
switch_namespace() {
    local target_namespace="$1"
    
    # Verificar que el namespace existe
    if ! kubectl get namespace "$target_namespace" &>/dev/null; then
        print_error "Namespace '$target_namespace' no existe"
        
        # Ofrecer crear el namespace
        if confirm "¿Deseas crear el namespace '$target_namespace'?"; then
            kubectl create namespace "$target_namespace"
            print_success "Namespace '$target_namespace' creado"
        else
            return 1
        fi
    fi
    
    # Cambiar namespace en el contexto actual
    kubectl config set-context --current --namespace="$target_namespace"
    print_success "Cambiado a namespace: $target_namespace"
    
    show_current
}

# Crear contexto rápido
create_quick_context() {
    local context_name="$1"
    local cluster="$2"
    local user="$3"
    local namespace="${4:-default}"
    
    print_info "Creando contexto '$context_name'..."
    
    kubectl config set-context "$context_name" \
        --cluster="$cluster" \
        --user="$user" \
        --namespace="$namespace"
    
    print_success "Contexto '$context_name' creado exitosamente"
    
    if confirm "¿Deseas cambiar a este contexto ahora?"; then
        switch_context "$context_name"
    fi
}

# Cambio interactivo con fzf (si está instalado)
interactive_context_switch() {
    if ! command -v fzf &> /dev/null; then
        print_warning "fzf no está instalado. Usa: brew install fzf (macOS) o apt install fzf (Linux)"
        return 1
    fi
    
    local selected_context
    selected_context=$(kubectl config get-contexts -o name | fzf --height=40% --header="Selecciona contexto:")
    
    if [[ -n "$selected_context" ]]; then
        switch_context "$selected_context"
    else
        print_info "No se seleccionó ningún contexto"
    fi
}

interactive_namespace_switch() {
    if ! command -v fzf &> /dev/null; then
        print_warning "fzf no está instalado"
        return 1
    fi
    
    local selected_namespace
    selected_namespace=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | fzf --height=40% --header="Selecciona namespace:")
    
    if [[ -n "$selected_namespace" ]]; then
        switch_namespace "$selected_namespace"
    else
        print_info "No se seleccionó ningún namespace"
    fi
}

# =============================================================================
# MENÚ PRINCIPAL
# =============================================================================

show_menu() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║  Kubernetes Context Switcher           ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "  1) Mostrar configuración actual"
    echo "  2) Listar contextos"
    echo "  3) Cambiar contexto"
    echo "  4) Cambiar contexto (interactivo)"
    echo "  5) Listar namespaces"
    echo "  6) Cambiar namespace"
    echo "  7) Cambiar namespace (interactivo)"
    echo "  8) Crear contexto rápido"
    echo "  9) Volver al contexto anterior"
    echo "  0) Salir"
    echo ""
}

main_menu() {
    local choice
    
    while true; do
        show_menu
        read -p "Selecciona una opción: " choice
        
        case $choice in
            1)
                show_current
                ;;
            2)
                list_contexts
                ;;
            3)
                read -p "Nombre del contexto: " ctx_name
                switch_context "$ctx_name"
                ;;
            4)
                interactive_context_switch
                ;;
            5)
                list_namespaces
                ;;
            6)
                read -p "Nombre del namespace: " ns_name
                switch_namespace "$ns_name"
                ;;
            7)
                interactive_namespace_switch
                ;;
            8)
                read -p "Nombre del contexto: " ctx_name
                read -p "Cluster: " cluster
                read -p "Usuario: " user
                read -p "Namespace (default: default): " namespace
                namespace=${namespace:-default}
                create_quick_context "$ctx_name" "$cluster" "$user" "$namespace"
                ;;
            9)
                kubectl config use-context -
                print_success "Vuelto al contexto anterior"
                show_current
                ;;
            0)
                print_info "¡Hasta luego!"
                exit 0
                ;;
            *)
                print_error "Opción no válida"
                ;;
        esac
        
        echo ""
        read -p "Presiona Enter para continuar..."
    done
}

# =============================================================================
# PROCESAMIENTO DE ARGUMENTOS DE LÍNEA DE COMANDOS
# =============================================================================

usage() {
    cat << EOF
Uso: $0 [OPCIÓN] [ARGUMENTO]

Opciones:
  -c, --context CONTEXT    Cambiar a contexto
  -n, --namespace NS       Cambiar a namespace
  -l, --list-contexts      Listar contextos
  -s, --list-namespaces    Listar namespaces
  -i, --interactive        Modo interactivo (menú)
  -h, --help               Mostrar esta ayuda

Ejemplos:
  $0                       # Menú interactivo
  $0 -c production         # Cambiar a contexto 'production'
  $0 -n monitoring         # Cambiar a namespace 'monitoring'
  $0 -l                    # Listar contextos

EOF
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    check_dependencies
    
    # Si no hay argumentos, mostrar menú
    if [[ $# -eq 0 ]]; then
        main_menu
        exit 0
    fi
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--context)
                switch_context "$2"
                shift 2
                ;;
            -n|--namespace)
                switch_namespace "$2"
                shift 2
                ;;
            -l|--list-contexts)
                list_contexts
                shift
                ;;
            -s|--list-namespaces)
                list_namespaces
                shift
                ;;
            -i|--interactive)
                main_menu
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                print_error "Opción desconocida: $1"
                usage
                exit 1
                ;;
        esac
    done
}

main "$@"

# =============================================================================
# INSTALACIÓN COMO ALIAS
# =============================================================================
#
# Agregar a ~/.bashrc o ~/.zshrc:
#
# alias kctx='~/path/to/context-switching.sh -c'
# alias kns='~/path/to/context-switching.sh -n'
# alias kcurrent='~/path/to/context-switching.sh'
#
# Luego:
#   kctx production      # Cambiar a contexto 'production'
#   kns monitoring       # Cambiar a namespace 'monitoring'
#   kcurrent             # Mostrar contexto/namespace actual
#
# =============================================================================
