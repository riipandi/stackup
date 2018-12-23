#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

echo "deb https://packages.sury.org/wireguard/ `lsb_release -cs` main" > /etc/apt/sources.list.d/wireguard.list
curl -sS https://packages.sury.org/wireguard/apt.gpg | apt-key add - && apt update

apt -yqq install wireguard wireguard-dkms wireguard-tools qrencode

# source $ROOT/wireguard/configure.sh

# Enable package forwarding
crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.all.forwarding' '1'
sysctl -p -q >/dev/null 2>&1

# Generate server key
cd /etc/wireguard ; umask 077
wg genkey | tee privatekey | wg pubkey > publickey

# Please allow 51820/udp and 22/tcp
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $(cat /etc/wireguard/privatekey)
Address = 10.0.0.1/24
ListenPort = 51820
SaveConfig = true
EOF

# Starting Wireguard server
wg-quick up wg0
systemctl enable wg-quick@wg0
ifconfig wg0 ; wg show

# wg-quick down wg0
