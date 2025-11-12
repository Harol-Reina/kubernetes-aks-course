#!/bin/bash

################################################################################
# Script: kubectl-autocomplete-bash.sh
# Descripción: Configuración de autocompletado para kubectl en Bash
# Uso: ./kubectl-autocomplete-bash.sh
# Requisitos: kubectl instalado, bash-completion instalado
################################################################################

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Configurando autocompletado de kubectl para Bash...${NC}"
echo ""

# Verificar que kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}[WARNING]${NC} kubectl no está instalado"
    echo "Instala kubectl primero: ejemplos/01-instalacion/install-kubectl.sh"
    exit 1
fi

# Verificar que bash-completion está instalado
if ! dpkg -l | grep -q bash-completion; then
    echo -e "${YELLOW}[INFO]${NC} Instalando bash-completion..."
    sudo apt-get update -qq
    sudo apt-get install -y bash-completion
fi

# Generar script de autocompletado
echo -e "${GREEN}[INFO]${NC} Generando script de autocompletado..."
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

# Agregar configuración a .bashrc si no existe
if ! grep -q "kubectl completion bash" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# kubectl autocompletion" >> ~/.bashrc
    echo "source <(kubectl completion bash)" >> ~/.bashrc
    echo -e "${GREEN}[INFO]${NC} Agregado a ~/.bashrc"
fi

# Configurar alias 'k' para kubectl
if ! grep -q "alias k=kubectl" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# kubectl alias" >> ~/.bashrc
    echo "alias k=kubectl" >> ~/.bashrc
    echo "complete -o default -F __start_kubectl k" >> ~/.bashrc
    echo -e "${GREEN}[INFO]${NC} Alias 'k' configurado"
fi

echo ""
echo -e "${GREEN}✓ Autocompletado configurado correctamente${NC}"
echo ""
echo -e "${YELLOW}Para aplicar los cambios:${NC}"
echo -e "  ${BLUE}source ~/.bashrc${NC}"
echo -e "  O cierra y vuelve a abrir la terminal"
echo ""
echo -e "${YELLOW}Prueba el autocompletado:${NC}"
echo -e "  ${BLUE}kubectl get po<TAB>${NC}     # Autocompletar 'pods'"
echo -e "  ${BLUE}kubectl get pods -n <TAB>${NC}  # Autocompletar namespaces"
echo -e "  ${BLUE}k get no<TAB>${NC}           # Usando el alias 'k'"
echo ""

exit 0
