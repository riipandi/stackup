#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
NOCOLOR='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;33m'
BLUE='\033[0;34m'
CURRENT=$(dirname $(readlink -f $0))
[ -z $ROOTDIR ] && PWD=$(dirname $CURRENT) || PWD=$ROOTDIR

#----------------------------------------------------------------------------------
# --
#----------------------------------------------------------------------------------

echo -e "${BLUE}\nCurrent server hostname is: ${RED}$(hostname -f)\n${NOCOLOR}"

# Server hostname
read -ep "Change server hostname?                     y/n : " -i "n" answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Enter server hostname                           : " -i "$(hostname -f)" answer
    hostnamectl set-hostname $answer
fi

# Create new user
#-----------------------------------------------------------------------------------------
createNewUser() {
    while true; do
        read -ep "Enter username for this user                    : " -i "admin" username
        read -ep "Enter new user real name                        : " -i "${username^}" fullname
        egrep "^$username" /etc/passwd >/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${RED}User $username already exists!${NOCOLOR}"
        else
            while true; do
                read -sp "Enter password for new user                     : " password
                if [ "$password" == "" ]; then
                    echo -e "${RED}\nPlease enter user password!${NOCOLOR}"
                else
                    password="$password" && break && echo
                fi
            done
            # Create new user
            pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
            useradd -mg webmaster -s `which bash` $username -c "$fullname" -p $pass
            usermod -a -G sudo $username
            if [ $? -eq 0 ] ; then
                HOMEDIR=$(eval echo "~$username")
                mkdir -p $HOMEDIR/.ssh ; chmod 0700 $_
                touch $HOMEDIR/.ssh/id_rsa ; chmod 0600 $_
                touch $HOMEDIR/.ssh/id_rsa.pub ; chmod 0600 $_
                touch $HOMEDIR/.ssh/authorized_keys ; chmod 0600 $_
                chown -R $username: $HOMEDIR/.ssh

                echo
                read -ep "Configure development environment?          y/n : " -i "y" answer
                if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
                    # Composer environment
                    if [ -x "$(command -v composer)" ]; then
                        echo -e "${BLUE}\nConfiguring Composer environment..${NOCOLOR}"
                        runuser -l $username -c 'composer global require hirak/prestissimo --quiet'
                        if ! grep -q 'composer' /home/$username/.bashrc ; then
                            echo 'export PATH=$PATH:$HOME/.config/composer/vendor/bin' >> "/home/$username/.bashrc"
                        fi
                    fi

                    # NodeJS environment
                    if [ -x "$(command -v yarn)" ]; then
                        echo -e "${BLUE}\nConfiguring NodeJS environment..${NOCOLOR}"
                        runuser -l $username -c 'sudo npm i -g ghost-cli@latest &>/dev/null'
                        if ! grep -q 'yarn' /home/$username/.bashrc ; then
                            echo 'export PATH=$PATH:$HOME/.yarn/bin' >> "/home/$username/.bashrc"
                        fi
                    fi
                fi

                echo -e "${BLUE}\nUser ${RED}$username${NOCOLOR} ${BLUE}has been added to system!${NOCOLOR}"
            else
                echo -e "${RED}Failed to add a user!${NOCOLOR}"
            fi
            break
        fi
    done
}

perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers
[[ $(cat /etc/group | grep -c webmaster) -eq 1 ]] || groupadd -g 3000 webmaster
read -ep "Create new system user?                     y/n : " -i "n" answer
[[ "${answer,,}" =~ ^(yes|y)$ ]] && createNewUser && echo

# Configure Timezone, SSH server + welcome message
#-----------------------------------------------------------------------------------------
read -ep "Please specify time zone                        : " -i "Asia/Jakarta" timezone
read -ep "Dou you want to enable root login ?      yes/no : " -i "no" ssh_root_login
read -ep "Please specify SSH port                         : " -i "22" ssh_port

sed -i "s/#ListenAddress :://" /etc/ssh/sshd_config
sed -i "s/[#]*PasswordAuthentication/PasswordAuthentication/" /etc/ssh/sshd_config
sed -i "s/[#]*PubkeyAuthentication/PubkeyAuthentication/" /etc/ssh/sshd_config
sed -i "s/[#]*ClientAliveInterval/ClientAliveInterval/" /etc/ssh/sshd_config
sed -i "s/[#]*AllowTcpForwarding/AllowTcpForwarding/" /etc/ssh/sshd_config
sed -i "s/[#]*ClientAliveCountMax/ClientAliveCountMax/" /etc/ssh/sshd_config
sed -i "s/[#]*PermitRootLogin/PermitRootLogin/" /etc/ssh/sshd_config
sed -i "s/[#]*ListenAddress/ListenAddress/" /etc/ssh/sshd_config
sed -i "s/[#]*PermitTunnel/PermitTunnel/" /etc/ssh/sshd_config
sed -i "s/[#]*X11Forwarding/X11Forwarding/" /etc/ssh/sshd_config
sed -i "s/[#]*StrictModes/StrictModes/" /etc/ssh/sshd_config
sed -i "s|\("^PermitRootLogin" * *\).*|\1$ssh_root_login|" /etc/ssh/sshd_config
sed -i "s|\("^PasswordAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^PubkeyAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveInterval" * *\).*|\1600|" /etc/ssh/sshd_config
sed -i "s|\("^AllowTcpForwarding" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^ClientAliveCountMax" * *\).*|\13|" /etc/ssh/sshd_config
sed -i "s|\("^ListenAddress" * *\).*|\10.0.0.0|" /etc/ssh/sshd_config
sed -i "s|\("^PermitTunnel" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s|\("^X11Forwarding" * *\).*|\1no|" /etc/ssh/sshd_config
sed -i "s|\("^StrictModes" * *\).*|\1yes|" /etc/ssh/sshd_config
sed -i "s/[#]*Port [0-9]*/Port $ssh_port/" /etc/ssh/sshd_config
echo && echo -e "\n$(figlet `hostname -s`)\n" > /etc/motd

[[ $(which ntp) -ne 0 ]] && apt purge -yqq ntp ntpdate
timedatectl set-ntp true
timedatectl set-timezone $timezone
systemctl enable systemd-timesyncd
systemctl restart systemd-timesyncd
systemctl restart ssh

# Disable IPv6
#-----------------------------------------------------------------------------------------
read -ep "Do you want to disable IPv6?                y/n : " -i "y" answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    sed -i "s/ListenAddress :://" /etc/ssh/sshd_config
    sed -i "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.all.disable_ipv6'     '1'
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.default.disable_ipv6' '1'
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.lo.disable_ipv6'      '1'
    echo -e 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
    sysctl -p -q
fi

# Sysctl tweak
#-----------------------------------------------------------------------------------------
crudini --set /etc/sysctl.conf '' 'net.ipv4.ip_forward'   '1'
crudini --set /etc/sysctl.conf '' 'vm.vfs_cache_pressure' '50'
crudini --set /etc/sysctl.conf '' 'vm.swappiness'         '10'
sysctl -p -q >/dev/null 2>&1

# Linux SWAP
#-----------------------------------------------------------------------------------------
if (( $memoryTotal >= 2097152 )); then opsi="n"; else opsi="y"; fi
read -ep "Do you want to setup Linux Swap?            y/n : " -i "$opsi" answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Enter size of Swap (in megabyte)                : " -i "2048" swap_size
    if [[ $(cat /etc/fstab | grep -c "swapfile") -eq 0 ]]; then
        echo -e "\n${BLUE}Configuring Linux SWAP...${NOCOLOR}\n"
        echo "/swapfile  none  swap  sw  0 0" >> /etc/fstab
        dd if=/dev/zero of=/swapfile count=$swap_size bs=1M
        chmod 600 /swapfile && mkswap /swapfile
        swapon /swapfile && swapon --show
    else
        echo -e "\n${BLUE}Swapfile already configured...${NOCOLOR}"
    fi
fi
