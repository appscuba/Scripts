#!/bin/bash

# Función para mostrar progreso
show_progress() {
    while read -r line; do
        case $line in
            *[Pp]rogress*)
                percent=$(echo "$line" | grep -oE '[0-9]+%')
                printf "\r🚀 Progreso: %-10s" "$percent"
                ;;
            *[Ee]rror*)
                printf "\n❌ Error: %s\n" "$line"
                exit 1
                ;;
            *[Cc]ompletado*)
                printf "\r✅ Proceso completado!    \n"
                ;;
        esac
    done
}

# Menú principal
echo -e "\n🔧 Scripts de instalación disponibles:"
echo "-----------------------------------------------"
echo "1. 🌐 Nextcloud (Almacenamiento en la nube)"
echo "2. 🛡️ WireGuard (VPN segura)"
echo "3. 🐧 Utilerías Linux"
echo "-----------------------------------------------"

read -p "👉 Seleccione una opción (1-3): " option

case $option in
    1)
        echo -e "\n📥 Iniciando instalación de Nextcloud..."
        source ./scripts/install_nextcloud.sh | show_progress
        ;;
    2)
        echo -e "\n📡 Iniciando instalación de WireGuard..."
        source ./scripts/install_wireguard.sh | show_progress
        ;;
    3)
        echo -e "\n🔧 Instalando utilerías del sistema..."
        source ./scripts/install_utils.sh | show_progress
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac

echo -e "\n✨ ¡Instalación finalizada! Verifique los logs en /var/log/installer.log"
