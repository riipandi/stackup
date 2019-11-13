#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;33m'
BLUE='\033[0;34m'
CURRENT=$(dirname $(readlink -f $0))
[ -z $ROOTDIR ] && PWD=$(dirname `dirname $CURRENT`) || PWD=$ROOTDIR

#-----------------------------------------------------------------------------------------
echo -e "\n${BLUE}Installing Nginx...${NOCOLOR}"
#-----------------------------------------------------------------------------------------
! [[ -z $(which nginx) ]] && echo -e "${BLUE}Already installed...${NOCOLOR}" && exit 1

# Install packages
#-----------------------------------------------------------------------------------------
curl -sS http://nginx.org/keys/nginx_signing.key | apt-key add - &>/dev/null
cat > /etc/apt/sources.list.d/nginx.list <<EOF
deb [arch=amd64] https://nginx.org/packages/mainline/debian `lsb_release -cs` nginx
EOF

apt update -qq ; apt full-upgrade -yqq
apt -yqq install {libpng,libssl,libffi,libexpat1}-dev libarchive-tools libimage-exiftool-perl \
libaugeas0 haveged gamin nginx augeas-lenses python-dev openssl

# Download latest certbot
echo -e "\n${BLUE}Downloading certbot and trusted certificates...${NOCOLOR}"
curl -L# https://dl.eff.org/certbot-auto -o /usr/bin/certbot ; chmod a+x /usr/bin/certbot
curl -L# https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem.txt -o /etc/ssl/certs/chain.pem
curl -L# https://2ton.com.au/dhparam/4096 -o /etc/ssl/certs/dhparam-4096.pem
curl -L# https://2ton.com.au/dhparam/2048 -o /etc/ssl/certs/dhparam-2048.pem

# Configure packages
#-----------------------------------------------------------------------------------------
