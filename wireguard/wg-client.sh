#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

echo
read -ep "Enter client name (no space or special character) : " clientID

# Validate existing vhost
if [[ -d "/etc/wireguard/$clientID" ]]; then
    echo -e "\nThis client already exist...\n"
    exit 1
fi

# Client IP Address
read -ep "Enter client IP Address (only IPv4 allowed)       : " -i "10.0.0.2" clientIP

# Generate client key
mkdir -p /etc/wireguard/$clientID ; cd $_ ; umask 077
wg genkey | tee privatekey | wg pubkey > publickey

cat > /etc/wireguard/$clientID/client.conf <<EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/${clientID}/privatekey)
Address = ${clientIP}/24

[Peer]
PublicKey = $(cat /etc/wireguard/publickey)
Endpoint = $(curl -s ifconfig.me):51820
AllowedIPs = 10.0.0.0/24
EOF

# Add client to server (run at server)
wg set wg0 peer $(cat /etc/wireguard/$clientID/publickey) allowed-ips $clientIP/24
wg-quick save wg0 ; wg show ; echo

# Generate QRCode
qrencode -t ansiutf8 < /etc/wireguard/$clientID/client.conf

wg-quick down wg0
wg-quick up wg0
