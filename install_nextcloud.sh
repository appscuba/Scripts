#!/bin/bash

install_nextcloud() {
    # Registro de pasos
    STEPS=8
    CURRENT_STEP=1

    echo "Progress: $((CURRENT_STEP*100/STEPS))% - Verificando dependencias"
    # ... (tu código de verificación de PHP aquí)
    
    ((CURRENT_STEP++))
    echo "Progress: $((CURRENT_STEP*100/STEPS))% - Creando directorios"
    # ... (código de creación de directorios)
    
    ((CURRENT_STEP++))
    echo "Progress: $((CURRENT_STEP*100/STEPS))% - Descargando Nextcloud"
    # ... (código de descarga)
    
    # Repetir para cada paso...
    
    echo "Progress: 100% - Completado"
}

# Ejecutar instalación
install_nextcloud 2>&1 | tee -a /var/log/installer.log
