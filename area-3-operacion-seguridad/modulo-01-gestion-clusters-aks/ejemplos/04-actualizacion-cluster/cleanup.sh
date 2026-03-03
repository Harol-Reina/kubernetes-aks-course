#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🧹 Nota: Las actualizaciones de cluster no se pueden revertir.${NC}"
echo -e "${YELLOW}   El cluster permanece en la versión actualizada.${NC}"
echo -e "${GREEN}🎉 No se requiere limpieza adicional.${NC}"
