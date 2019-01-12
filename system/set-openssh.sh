#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

[ -z $ROOT ] && PARENT=$(dirname "$(readlink -f "$0")") || PARENT=$ROOT

# Get parameter
#-----------------------------------------------------------------------------------------
SSH_PORT=`crudini --get $PARENT/config.ini system ssh_port`
TELEGRAM_NOTIFY=`crudini --get $PARENT/config.ini telegram enable`
TELEGRAM_BOTKEY=`crudini --get $PARENT/config.ini telegram bot_key`
TELEGRAM_CHATID=`crudini --get $PARENT/config.ini telegram chat_id`

# Disable sudo password
perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers

# Download ssh moduli parameter
curl -L# https://2ton.com.au/dhparam/4096/ssh -o /etc/ssh/moduli

## SSH Server + welcome message
sed -i "s/[#]*PubkeyAuthentication/PubkeyAuthentication/" /etc/ssh/sshd_config
sed -i "s|\("^PubkeyAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveInterval" * *\).*|\1600|" /etc/ssh/sshd_config
sed -i "s|\("^AllowTcpForwarding" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveCountMax" * *\).*|\13|" /etc/ssh/sshd_config
sed -i "s|\("^ListenAddress" * *\).*|\10.0.0.0|" /etc/ssh/sshd_config
sed -i "s|\("^PermitRootLogin" * *\).*|\1no|" /etc/ssh/sshd_config
sed -i "s|\("^PermitTunnel" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^StrictModes" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s/[#]*Port [0-9]*/Port $SSH_PORT/" /etc/ssh/sshd_config
systemctl restart ssh

# Set custom motd message
echo -e "$(figlet node://`hostname -s`)\n" > /etc/motd

# Telegram notification
if [ $TELEGRAM_NOTIFY == "yes" ]; then
    sed -i "s/VAR_BOTKEY/$TELEGRAM_BOTKEY/" $PARENT/system/telegram.sh
    sed -i "s/VAR_CHATID/$TELEGRAM_CHATID/" $PARENT/system/telegram.sh
    cp $PARENT/system/telegram.sh /etc/profile.d/ ; chmod +x $_
fi
