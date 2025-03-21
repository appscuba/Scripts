#!/bin/bash

# Configuración inicial
NC_DIR="/var/www/nextcloud"
DATA_DIR="/mnt/nextcloud_data"
DB_USER="nextcloud"
DB_PASS=$(openssl rand -base64 16)
DB_NAME="nextcloud_db"
ADMIN_USER="admin"
ADMIN_PASS=$(openssl rand -base64 12)

# Función para mostrar progreso
progress() {
    steps=8
    current=$1
    percent=$((100 * current / steps))
    printf "\n[%-${steps}s] %d%%" $(seq -s# $current | tr -d '[:digit:]') $percent
}

# Verificar dependencias (Paso 1/8)
progress 1
if ! command -v php &> /dev/null; then
    apt-get install -y php-fpm php-mysql php-curl php-gd php-xml php-mbstring php-zip php-bz2 php-intl php-apcu
fi

# Crear directorios (Paso 2/8)
progress 2
[ ! -d "$NC_DIR" ] && mkdir -p "$NC_DIR"
[ ! -d "$DATA_DIR" ] && mkdir -p "$DATA_DIR"
chown -R www-data:www-data "$DATA_DIR"

# Descargar Nextcloud (Paso 3/8)
progress 3
wget -q https://download.nextcloud.com/server/releases/latest.zip -P /tmp
unzip -q /tmp/latest.zip -d /var/www/
rm /tmp/latest.zip

# Configurar base de datos (Paso 4/8)
progress 4
mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Instalación automática (Paso 5/8)
progress 5
sudo -u www-data php $NC_DIR/occ maintenance:install \
    --database "mysql" \
    --database-name "$DB_NAME" \
    --database-user "$DB_USER" \
    --database-pass "$DB_PASS" \
    --admin-user "$ADMIN_USER" \
    --admin-pass "$ADMIN_PASS" \
    --data-dir "$DATA_DIR" > /tmp/nextcloud-install.log 2>&1

# Verificar errores comunes (Paso 6/8)
progress 6
if grep -q "SQLSTATE[42S02]" /tmp/nextcloud-install.log; then
    echo -e "\n❌ Error en la base de datos: Tablas no encontradas"
    mysql -e "DROP DATABASE $DB_NAME;"
    mysql -e "CREATE DATABASE $DB_NAME;"
    echo "Reintentando instalación..."
    sudo -u www-data php $NC_DIR/occ maintenance:install --force
fi

# Configurar dominios confiables (Paso 7/8)
progress 7
CURRENT_IP=$(hostname -I | awk '{print $1}')
sudo -u www-data php $NC_DIR/occ config:system:set trusted_domains 1 --value="$CURRENT_IP"
sudo -u www-data php $NC_DIR/occ config:system:set trusted_domains 2 --value="localhost"

# Configuración de seguridad (Paso 8/8)
progress 8
sudo -u www-data php $NC_DIR/occ config:system:set filelocking.enabled --value=true
sudo -u www-data php $NC_DIR/occ config:system:set memcache.local --value="\OC\Memcache\APCu"
sudo -u www-data php $NC_DIR/occ maintenance:update:htaccess

echo -e "\n✅ Instalación completada!"
echo "==============================="
echo "Admin User: $ADMIN_USER"
echo "Admin Pass: $ADMIN_PASS"
echo "Database: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Pass: $DB_PASS"
echo "Acceso: http://$CURRENT_IP/nextcloud"
