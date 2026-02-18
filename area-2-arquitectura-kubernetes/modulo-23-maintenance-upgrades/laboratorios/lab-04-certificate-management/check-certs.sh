#!/bin/bash

################################################################################
# Check Certificates Script - Lab 04
# 
# Este script verifica el estado de todos los certificados de Kubernetes,
# mostrando fechas de expiración y tiempo restante.
#
# Uso:
#   ./check-certs.sh [--detailed]
#
# Opciones:
#   --detailed    Muestra información extendida de cada certificado
################################################################################

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuración
PKI_DIR="/etc/kubernetes/pki"
DETAILED=false

################################################################################
# Funciones de Utilidad
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

usage() {
    echo "Uso: $0 [--detailed]"
    echo ""
    echo "Opciones:"
    echo "  --detailed    Información extendida de certificados"
    echo ""
    exit 0
}

################################################################################
# Verificación de Prerequisitos
################################################################################

check_prerequisites() {
    # Verificar kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl no encontrado"
        exit 1
    fi
    
    # Verificar kubeadm
    if ! command -v kubeadm &> /dev/null; then
        log_error "kubeadm no encontrado (necesario para este lab)"
        exit 1
    fi
    
    # Verificar openssl
    if ! command -v openssl &> /dev/null; then
        log_error "openssl no encontrado"
        exit 1
    fi
    
    # Verificar acceso a PKI
    if ! sudo test -d "$PKI_DIR"; then
        log_error "Directorio PKI no accesible: $PKI_DIR"
        exit 1
    fi
}

################################################################################
# Verificación 1: kubeadm certs check-expiration
################################################################################

check_with_kubeadm() {
    log_section "VERIFICACIÓN 1: KUBEADM CERTS CHECK"
    
    log_info "Ejecutando: kubeadm certs check-expiration"
    echo ""
    
    if sudo kubeadm certs check-expiration; then
        log_success "Comando ejecutado exitosamente"
    else
        log_error "Fallo al ejecutar kubeadm certs check-expiration"
        return 1
    fi
}

################################################################################
# Verificación 2: Certificados Individuales con openssl
################################################################################

check_individual_certs() {
    log_section "VERIFICACIÓN 2: CERTIFICADOS INDIVIDUALES"
    
    log_info "Verificando certificados en $PKI_DIR"
    echo ""
    
    # Encontrar todos los archivos .crt
    local certs=$(sudo find "$PKI_DIR" -name "*.crt" | sort)
    
    if [[ -z "$certs" ]]; then
        log_error "No se encontraron certificados en $PKI_DIR"
        return 1
    fi
    
    # Tabla header
    printf "${BOLD}%-60s %-20s %-12s${NC}\n" "CERTIFICADO" "EXPIRA" "DÍAS REST."
    printf "%-60s %-20s %-12s\n" "$(printf '%.0s-' {1..60})" "$(printf '%.0s-' {1..20})" "$(printf '%.0s-' {1..12})"
    
    while IFS= read -r cert; do
        local cert_name=$(basename "$cert")
        local cert_dir=$(dirname "$cert" | sed "s|$PKI_DIR/||")
        
        if [[ "$cert_dir" == "$PKI_DIR" ]]; then
            local full_name="$cert_name"
        else
            local full_name="$cert_dir/$cert_name"
        fi
        
        # Obtener fecha de expiración
        local expiry_date=$(sudo openssl x509 -in "$cert" -noout -enddate 2>/dev/null | cut -d= -f2)
        
        if [[ -z "$expiry_date" ]]; then
            printf "%-60s ${RED}%-20s %-12s${NC}\n" "$full_name" "ERROR" "N/A"
            continue
        fi
        
        # Calcular días restantes
        local expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
        local now_epoch=$(date +%s)
        local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
        
        # Formatear fecha
        local expiry_formatted=$(date -d "$expiry_date" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "UNKNOWN")
        
        # Color según días restantes
        if [[ $days_left -lt 30 ]]; then
            printf "%-60s ${RED}%-20s %-12s${NC}\n" "$full_name" "$expiry_formatted" "${days_left}d"
        elif [[ $days_left -lt 90 ]]; then
            printf "%-60s ${YELLOW}%-20s %-12s${NC}\n" "$full_name" "$expiry_formatted" "${days_left}d"
        else
            printf "%-60s ${GREEN}%-20s %-12s${NC}\n" "$full_name" "$expiry_formatted" "${days_left}d"
        fi
    done <<< "$certs"
    
    echo ""
    log_info "Leyenda: ${RED}< 30 días${NC} | ${YELLOW}30-90 días${NC} | ${GREEN}> 90 días${NC}"
}

################################################################################
# Verificación 3: Detalles Extendidos (Opcional)
################################################################################

check_detailed_info() {
    log_section "VERIFICACIÓN 3: INFORMACIÓN DETALLADA"
    
    log_info "Mostrando detalles de cada certificado..."
    echo ""
    
    local certs=$(sudo find "$PKI_DIR" -name "*.crt" | sort)
    
    while IFS= read -r cert; do
        local cert_name=$(basename "$cert")
        local cert_dir=$(dirname "$cert")
        
        echo "═══════════════════════════════════════════════════════════"
        echo "Certificado: $cert"
        echo "───────────────────────────────────────────────────────────"
        
        # Subject
        echo -n "Subject:   "
        sudo openssl x509 -in "$cert" -noout -subject 2>/dev/null | sed 's/subject=//'
        
        # Issuer
        echo -n "Issuer:    "
        sudo openssl x509 -in "$cert" -noout -issuer 2>/dev/null | sed 's/issuer=//'
        
        # Validity
        echo "Validity:"
        sudo openssl x509 -in "$cert" -noout -dates 2>/dev/null | sed 's/^/  /'
        
        # Days left
        local expiry_date=$(sudo openssl x509 -in "$cert" -noout -enddate 2>/dev/null | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
        local now_epoch=$(date +%s)
        local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
        
        if [[ $days_left -lt 30 ]]; then
            echo -e "${RED}Days left: $days_left${NC}"
        elif [[ $days_left -lt 90 ]]; then
            echo -e "${YELLOW}Days left: $days_left${NC}"
        else
            echo -e "${GREEN}Days left: $days_left${NC}"
        fi
        
        # SANs (Subject Alternative Names)
        echo "SANs:"
        sudo openssl x509 -in "$cert" -noout -ext subjectAltName 2>/dev/null | grep -v "X509v3" | sed 's/^/  /' || echo "  (none)"
        
        echo ""
    done <<< "$certs"
}

################################################################################
# Verificación 4: Kubeconfigs
################################################################################

check_kubeconfigs() {
    log_section "VERIFICACIÓN 4: KUBECONFIG CERTIFICATES"
    
    log_info "Verificando certificados embebidos en kubeconfigs..."
    echo ""
    
    local configs=("/etc/kubernetes/admin.conf" "/etc/kubernetes/controller-manager.conf" "/etc/kubernetes/scheduler.conf")
    
    for config in "${configs[@]}"; do
        if ! sudo test -f "$config"; then
            log_warning "$(basename $config) no encontrado"
            continue
        fi
        
        log_info "Verificando: $(basename $config)"
        
        # Extraer certificado embebido
        local cert_data=$(sudo cat "$config" | grep "client-certificate-data" | awk '{print $2}')
        
        if [[ -z "$cert_data" ]]; then
            log_warning "  No se pudo extraer certificado de $(basename $config)"
            continue
        fi
        
        # Decodificar y verificar
        local expiry=$(echo "$cert_data" | base64 -d | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
        
        if [[ -n "$expiry" ]]; then
            local expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            local now_epoch=$(date +%s)
            local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
            
            if [[ $days_left -lt 30 ]]; then
                echo -e "  Expira: ${RED}$expiry ($days_left días)${NC}"
            elif [[ $days_left -lt 90 ]]; then
                echo -e "  Expira: ${YELLOW}$expiry ($days_left días)${NC}"
            else
                echo -e "  Expira: ${GREEN}$expiry ($days_left días)${NC}"
            fi
        else
            log_warning "  No se pudo obtener fecha de expiración"
        fi
    done
}

################################################################################
# Verificación 5: Recomendaciones
################################################################################

show_recommendations() {
    log_section "VERIFICACIÓN 5: RECOMENDACIONES"
    
    log_info "Analizando estado de certificados..."
    echo ""
    
    # Encontrar certificados próximos a expirar
    local certs=$(sudo find "$PKI_DIR" -name "*.crt")
    local certs_expiring_soon=0
    local certs_expired=0
    
    while IFS= read -r cert; do
        local expiry_date=$(sudo openssl x509 -in "$cert" -noout -enddate 2>/dev/null | cut -d= -f2)
        
        if [[ -n "$expiry_date" ]]; then
            local expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
            local now_epoch=$(date +%s)
            local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
            
            if [[ $days_left -lt 0 ]]; then
                ((certs_expired++))
            elif [[ $days_left -lt 30 ]]; then
                ((certs_expiring_soon++))
            fi
        fi
    done <<< "$certs"
    
    # Mostrar recomendaciones
    if [[ $certs_expired -gt 0 ]]; then
        log_error "$certs_expired certificado(s) EXPIRADO(S)"
        echo ""
        echo "  ${RED}ACCIÓN URGENTE:${NC}"
        echo "    sudo kubeadm certs renew all"
        echo "    sudo systemctl restart kubelet"
        echo ""
    elif [[ $certs_expiring_soon -gt 0 ]]; then
        log_warning "$certs_expiring_soon certificado(s) expiran en menos de 30 días"
        echo ""
        echo "  ${YELLOW}RECOMENDACIÓN:${NC}"
        echo "    Planear renovación pronto:"
        echo "    sudo kubeadm certs renew all"
        echo ""
    else
        log_success "Todos los certificados tienen más de 30 días de validez"
        echo ""
        echo "  ${GREEN}ESTADO:${NC} OK"
        echo "  ${GREEN}PRÓXIMA ACCIÓN:${NC} Verificar nuevamente en 60-90 días"
        echo ""
    fi
    
    # Recordatorio de buenas prácticas
    echo "📚 Buenas prácticas:"
    echo "  • Verificar certificados mensualmente: kubeadm certs check-expiration"
    echo "  • Renovar con anticipación: 30-60 días antes de expiración"
    echo "  • Siempre hacer backup antes de renovar: cp -r /etc/kubernetes/pki /root/backup"
    echo "  • Configurar alertas de monitoreo para certificados"
}

################################################################################
# Resumen Final
################################################################################

show_summary() {
    log_section "RESUMEN"
    
    echo "Verificaciones completadas:"
    echo "  ✓ kubeadm certs check-expiration"
    echo "  ✓ Certificados individuales en $PKI_DIR"
    echo "  ✓ Kubeconfigs (admin, controller-manager, scheduler)"
    echo "  ✓ Recomendaciones de acción"
    echo ""
    
    log_info "Para renovar certificados, usa:"
    echo "  ./renew-certs.sh"
    echo ""
    
    log_info "Para más detalles, usa:"
    echo "  $0 --detailed"
}

################################################################################
# Main
################################################################################

main() {
    # Parsear argumentos
    if [[ "${1:-}" == "--detailed" ]]; then
        DETAILED=true
    elif [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        usage
    fi
    
    # Header
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        VERIFICACIÓN DE CERTIFICADOS - LAB 04          ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    # Verificar prerequisitos
    check_prerequisites
    
    # Ejecutar verificaciones
    check_with_kubeadm
    check_individual_certs
    
    if [[ "$DETAILED" == true ]]; then
        check_detailed_info
    fi
    
    check_kubeconfigs
    show_recommendations
    show_summary
}

main "$@"
