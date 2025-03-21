#!/bin/bash

# Configuración inicial
NC_DIR="/var/www/nextcloud"
DATA_DIR="/mnt/nextcloud_data"
DB_USER="nextcloud"
DB_PASS=$(openssl rand -base64 16)
DB_NAME="nextcloud_db"
ADMIN_USER="admin"
ADMIN_PASS=$(openssl rand -base64 12)

# Verificar dependencias
if ! command -v php &> /dev/null; then
    echo "Instalando dependencias PHP..."
    apt-get install -y php-fpm php-mysql php-curl php-gd php-xml php-mbstring php-zip php-bz2 php-intl php-apcu
fi

# Crear directorios
mkdir -p "$NC_DIR" "$DATA_DIR" || { echo "Error al crear directorios"; exit 1; }
chown -R www-data:www-data "$DATA_DIR"

# Descargar Nextcloud
wget -q -O /tmp/nextcloud.zip https://download.nextcloud.com/server/releases/latest.zip
unzip -q /tmp/nextcloud.zip -d /var/www/
rm /tmp/nextcloud.zip

# Configurar base de datos
mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Instalación automática
sudo -u www-data php "$NC_DIR/occ" maintenance:install \
    --database "mysql" \
    --database-name "$DB_NAME" \
    --database-user "$DB_USER" \
    --database-pass "$DB_PASS" \
    --admin-user "$ADMIN_USER" \
    --admin-pass "$ADMIN_PASS" \
    --data-dir "$DATA_DIR" > /dev/null 2>&1

# Configurar dominios confiables
CURRENT_IP=$(hostname -I | awk '{print $1}')
sudo -u www-data php "$NC_DIR/occ" config:system:set trusted_domains 1 --value="$CURRENT_IP"
sudo -u www-data php "$NC_DIR/occ" config:system:set trusted_domains 2 --value="localhost"

# Configuración de seguridad
sudo -u www-data php "$NC_DIR/occ" config:system:set filelocking.enabled --value=true
sudo -u www-data php "$NC_DIR/occ" config:system:set memcache.local --value="\OC\Memcache\APCu"
sudo -u www-data php "$NC_DIR/occ" maintenance:update:htaccess

# Mostrar resultados finales
echo -e "\n✅ Instalación completada!"
echo "==============================="
echo "Admin User: $ADMIN_USER"
echo "Admin Pass: $ADMIN_PASS"
echo "Database: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Pass: $DB_PASS"
echo "Acceso: http://$CURRENT_IP/nextcloud"
