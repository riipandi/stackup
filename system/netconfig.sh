#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then echo -e 'This script must be run as root' ; exit 1 ; fi

# NTP Client
# country=`crudini --get $ROOT/config.ini system country`
# if [ $country != "ID" ] || [ $country != "SG" ] ; then
#     ntpdate -u pool.ntp.org
# else
#     ntpdate -u 0.asia.pool.ntp.org
# fi

# Timezone Synchronization
apt purge -yqq ntp ntpdate ; timedatectl set-ntp true
timedatectl set-timezone `crudini --get $ROOT/config.ini system timezone`
systemctl enable systemd-timesyncd && systemctl restart systemd-timesyncd

if [[ `crudini --get $ROOT/config.ini system disable_ipv6` == "yes" ]] ; then
    echo -e "Disabling IPv6..."
    sed -i "s/ListenAddress :://" /etc/ssh/sshd_config
    sed -i "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.all.disable_ipv6'     '1'
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.default.disable_ipv6' '1'
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.lo.disable_ipv6'      '1'
    echo -e 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
    sysctl -p
fi

# Sysctl tweak
crudini --set /etc/sysctl.conf '' 'net.ipv4.ip_forward'   '1'
crudini --set /etc/sysctl.conf '' 'vm.vfs_cache_pressure' '50'
crudini --set /etc/sysctl.conf '' 'vm.swappiness'         '10'
sysctl -p -q

## SSH Server + welcome message
ssh_port=`crudini --get $ROOT/config.ini system ssh_port`
perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers
sed -i "s|\("^PubkeyAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveInterval" * *\).*|\1600|" /etc/ssh/sshd_config
sed -i "s|\("^AllowTcpForwarding" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveCountMax" * *\).*|\13|" /etc/ssh/sshd_config
sed -i "s|\("^ListenAddress" * *\).*|\10.0.0.0|" /etc/ssh/sshd_config
sed -i "s|\("^PermitRootLogin" * *\).*|\1no|" /etc/ssh/sshd_config
sed -i "s|\("^PermitTunnel" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^StrictModes" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s/[#]*ListenAddress/ListenAddress/" /etc/ssh/sshd_config
sed -i "s/[#]*Port [0-9]*/Port $ssh_port/" /etc/ssh/sshd_config
echo -e "$(figlet server://`hostname -s`)\n" > /etc/motd
systemctl restart ssh

##################

if [ `crudini --get $ROOT/config.ini tgnotif install` == "yes" ]; then

    tg_bot_key=`crudini --get $ROOT/config.ini tgnotif bot_key`
    tg_chat_id=`crudini --get $ROOT/config.ini tgnotif chat_id`

    cp $PWD/snippets/sshnotify /etc/profile.d/sshnotify.sh
    chmod a+x /etc/profile.d/sshnotify.sh

    sed -i "s/VAR_BOTKEY/$tg_bot_key/" /etc/profile.d/sshnotify.sh
    sed -i "s/VAR_CHATID/$tg_chat_id/" /etc/profile.d/sshnotify.sh

fi
