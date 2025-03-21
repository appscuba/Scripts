#!/bin/bash

# Configuración inicial
PORT=51820
DNS_SERVER="8.8.8.8"
CLIENT_NAME="cliente1"

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

# Instalación de WireGuard
echo "Progress: 10% - Instalando dependencias"
if ! command -v apt &> /dev/null; then
    echo "Error: Necesitas apt-get para continuar"
    exit 1
fi

echo "Progress: 20% - Actualizando repositorios"
apt update -y > /dev/null 2>&1

echo "Progress: 30% - Instalando WireGuard"
apt install -y wireguard resolvconf > /dev/null 2>&1

# Configuración del servidor
echo "Progress: 50% - Generando claves"
umask 077
wg genkey | tee privatekey | wg pubkey > publickey

echo "Progress: 60% - Creando configuración"
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.0.0.1/24
ListenPort = $PORT
PrivateKey = $(cat privatekey)
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = $(wg genkey | tee client_privatekey | wg pubkey)
AllowedIPs = 10.0.0.2/32
EOF

echo "Progress: 70% - Configurando firewall"
ufw allow $PORT/udp
ufw allow OpenSSH
echo "y" | ufw enable

echo "Progress: 80% - Generando perfil cliente"
cat > /tmp/client.conf <<EOF
[Interface]
PrivateKey = $(cat client_privatekey)
Address = 10.0.0.2/24
DNS = $DNS_SERVER

[Peer]
PublicKey = $(cat publickey)
Endpoint = $(hostname -I | awk '{print $1}'):${PORT}
AllowedIPs = 0.0.0.0/0
EOF

echo "Progress: 90% - Iniciando servicio"
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo "Progress: 100% - Completado"
echo -e "\n✨ Configuración finalizada:"
echo "-----------------------------"
echo "🔑 Clave pública del servidor:"
cat publickey
echo "📁 Archivo de configuración cliente:"
echo "/tmp/client.conf"
echo "🔒 IP del servidor: $(hostname -I | awk '{print $1}')"
echo "🔒 Puerto: $PORT"
echo "-----------------------------"
