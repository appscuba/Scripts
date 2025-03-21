#!/bin/bash

# Verificar permisos de ejecución
if [ ! -x "$0" ]; then
    echo "⚠️ Ejecuta este script con sudo: sudo ./$0"
    exit 1
fi

# Mostrar menú de opciones
echo -e "\n🌟 **Scripts disponibles en este proyecto:**"
echo "-----------------------------------------------"
echo "1. 🌐 **Instalar Nextcloud** (automatizado)"
echo "2. 📁 **Configurar herramientas de red**"
echo "3. 📊 **Analizar uso de disco**"
echo "4. 🛠️ **Verificar dependencias**"
echo "-----------------------------------------------"

read -p "👉 ¿Qué script deseas ejecutar? (1-4): " opcion

case $opcion in
    1) ./install_nextcloud.sh ;;
    2) ./config_red.sh ;;
    3) ./disk_usage.sh ;;
    4) ./check_dependencies.sh ;;
    *) echo "❌ Opción inválida"; exit 1 ;;
esac
