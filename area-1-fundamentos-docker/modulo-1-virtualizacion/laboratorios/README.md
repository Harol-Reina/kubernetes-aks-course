# Laboratorios - Módulo 1: Virtualización

> **Objetivo**: Comprender virtualización y crear tu primera VM en Azure  
> **Tiempo total estimado**: 60-90 minutos  
> **Nivel**: Principiante

## 📁 Estructura

```
laboratorios/
├── README.md                   # Este archivo
└── lab-01-azure-vm/           # Crear VM en Azure
    ├── README.md              # Instrucciones completas
    ├── SETUP.md               # Setup de cuenta Azure y SSH
    └── cleanup.sh             # Guía de limpieza
```

## 📋 Laboratorio Disponible

### [Lab 01: Azure VM Setup](./lab-01-azure-vm/) ⭐⭐
**Duración**: 60-90 minutos | **Dificultad**: Principiante

**Objetivos**:
- Crear cuenta de Azure (free tier)
- Crear primera máquina virtual Linux
- Conectarse via SSH
- Configurar reglas de firewall (NSG)
- Instalar software básico en VM
- Entender costos de cloud computing
- Eliminar recursos correctamente

**Archivos**:
- `README.md` - Instrucciones paso a paso con screenshots
- `SETUP.md` - Configuración de Azure y SSH
- `cleanup.sh` - Guía para eliminar recursos

**Conceptos cubiertos**:
- Virtualización en la nube
- Azure Portal navigation
- Resource Groups
- Virtual Networks
- Network Security Groups (NSG)
- Public IP addresses
- SSH key authentication
- VM sizing y costos

---

## 🚀 Guía de Uso

```bash
# Navegar al lab
cd lab-01-azure-vm/

# Leer prerequisitos
cat SETUP.md

# Seguir instrucciones paso a paso
cat README.md

# Al finalizar, limpiar recursos
chmod +x cleanup.sh
./cleanup.sh
```

## 🎯 Resultados de Aprendizaje

Después de completar este laboratorio, serás capaz de:

- [ ] Crear y configurar cuenta de Azure
- [ ] Navegar Azure Portal efectivamente
- [ ] Crear Resource Groups
- [ ] Crear y configurar una VM Linux
- [ ] Configurar SSH keys para acceso seguro
- [ ] Conectarse a VM via SSH
- [ ] Configurar reglas de firewall (NSG)
- [ ] Comprender conceptos de networking en cloud
- [ ] Instalar software en VM remota
- [ ] Calcular y optimizar costos de VM
- [ ] Eliminar recursos para evitar cargos

## 💡 Tips Importantes

### Antes de Empezar
- Usa free tier de Azure (750 horas/mes gratis primer año)
- Genera claves SSH antes de crear la VM
- Documenta usuarios/contraseñas que crees
- Ten un navegador moderno (Chrome, Firefox, Edge)

### Durante el Lab
- Usa VM tamaño **B1s** (más económica)
- Elige región cercana (mejor latencia)
- Guarda la clave privada SSH de forma segura
- Toma screenshots de configuraciones importantes

### Después del Lab
- **¡ELIMINA LA VM!** - Para evitar cargos
- Elimina el Resource Group completo (incluye todos los recursos)
- Verifica en portal que todo fue eliminado
- Revisa billing después de 24-48 horas

## 🔧 Troubleshooting Común

### "No puedo conectarme via SSH"
```bash
# Verificar que usas la clave correcta
ssh -i ~/.ssh/id_rsa azureuser@<IP>

# Verificar permisos de la clave
chmod 600 ~/.ssh/id_rsa

# Verificar regla NSG permite puerto 22
# En Azure Portal: VM → Networking → Inbound port rules
```

### "Connection refused"
- Verificar VM está corriendo (Status: Running)
- Verificar IP pública es correcta
- Verificar NSG permite puerto 22 desde tu IP

### "Azure me cobra y usé free tier"
- Free tier: Solo 750 horas/mes de B1s
- Si usas otro tamaño → se cobra
- Si dejas corriendo >750 horas → se cobra
- Otros recursos (storage, bandwidth) pueden tener cargos mínimos

## 🌐 Recursos Azure

- **Azure Portal**: [portal.azure.com](https://portal.azure.com)
- **Free Tier**: [azure.microsoft.com/free](https://azure.microsoft.com/free)
- **Students**: [azure.microsoft.com/students](https://azure.microsoft.com/students)
- **Pricing Calculator**: [azure.microsoft.com/pricing/calculator](https://azure.microsoft.com/pricing/calculator)
- **Docs**: [docs.microsoft.com/azure](https://docs.microsoft.com/azure)

## 📚 Conceptos Fundamentales

### ¿Qué es una VM en la nube?
- Servidor virtual corriendo en datacenter de Microsoft
- Pagas solo por lo que usas (por hora)
- Escalable: cambiar tamaño cuando quieras
- Eliminable: borrar cuando no necesitas

### ¿Por qué Azure?
- ✅ Free tier generoso (750 horas/mes)
- ✅ Interfaz amigable (portal web)
- ✅ Documentación excelente
- ✅ Integración con muchas herramientas
- ✅ Usado en empresas reales

### Próximo Paso: Docker
Una vez domines VMs, Docker te permitirá:
- Correr múltiples "mini-VMs" (contenedores) en una sola VM
- Deployment más rápido (segundos vs minutos)
- Menor consumo de recursos
- Portabilidad total

## 🎓 Próximos Pasos

1. Completa el Lab 01
2. Experimenta instalando diferentes software en tu VM
3. Practica conectándote via SSH varias veces
4. **¡No olvides eliminar la VM al terminar!**
5. Siguiente módulo: **Módulo 2 - Docker Fundamentals**

---

**¡Bienvenido a la nube! ☁️**

[Volver al módulo](../README.md)
