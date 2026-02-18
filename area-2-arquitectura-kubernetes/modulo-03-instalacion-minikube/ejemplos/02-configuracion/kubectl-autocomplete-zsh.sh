#!/bin/zsh

################################################################################
# Script: kubectl-autocomplete-zsh.sh
# Descripción: Configuración de autocompletado para kubectl en Zsh
# Uso: ./kubectl-autocomplete-zsh.sh
# Requisitos: kubectl instalado, zsh
################################################################################

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Configurando autocompletado de kubectl para Zsh...${NC}"
echo ""

# Verificar que kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}[WARNING]${NC} kubectl no está instalado"
    echo "Instala kubectl primero: ejemplos/01-instalacion/install-kubectl.sh"
    exit 1
fi

# Crear directorio para completions si no existe
COMPLETION_DIR="${HOME}/.zsh/completion"
mkdir -p "$COMPLETION_DIR"

# Generar script de autocompletado
echo -e "${GREEN}[INFO]${NC} Generando script de autocompletado..."
kubectl completion zsh > "${COMPLETION_DIR}/_kubectl"

# Agregar configuración a .zshrc si no existe
if ! grep -q "kubectl completion zsh" ~/.zshrc 2>/dev/null; then
    echo "" >> ~/.zshrc
    echo "# kubectl autocompletion" >> ~/.zshrc
    echo "fpath=(~/.zsh/completion \$fpath)" >> ~/.zshrc
    echo "autoload -Uz compinit" >> ~/.zshrc
    echo "compinit" >> ~/.zshrc
    echo -e "${GREEN}[INFO]${NC} Agregado a ~/.zshrc"
fi

# Configurar alias 'k' para kubectl
if ! grep -q "alias k=kubectl" ~/.zshrc 2>/dev/null; then
    echo "" >> ~/.zshrc
    echo "# kubectl alias" >> ~/.zshrc
    echo "alias k=kubectl" >> ~/.zshrc
    echo "compdef k=kubectl" >> ~/.zshrc
    echo -e "${GREEN}[INFO]${NC} Alias 'k' configurado"
fi

echo ""
echo -e "${GREEN}✓ Autocompletado configurado correctamente${NC}"
echo ""
echo -e "${YELLOW}Para aplicar los cambios:${NC}"
echo -e "  ${BLUE}source ~/.zshrc${NC}"
echo -e "  O cierra y vuelve a abrir la terminal"
echo ""
echo -e "${YELLOW}Prueba el autocompletado:${NC}"
echo -e "  ${BLUE}kubectl get po<TAB>${NC}     # Autocompletar 'pods'"
echo -e "  ${BLUE}kubectl get pods -n <TAB>${NC}  # Autocompletar namespaces"
echo -e "  ${BLUE}k get no<TAB>${NC}           # Usando el alias 'k'"
echo ""

exit 0
