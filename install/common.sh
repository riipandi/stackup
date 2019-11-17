#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi
[ -z $ROOTDIR ] && PWD=$(dirname $(dirname $(readlink -f $0))) || PWD=$ROOTDIR
source "$PWD/common.sh"

#----------------------------------------------------------------------------------
# --
#----------------------------------------------------------------------------------

msgInfo "\nCurrent server hostname is: ${red}$(hostname -f)${nocolor}\n"

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
            msgError "User $username already exists!"
        else
            while true; do
                read -sp "Enter password for new user                     : " password
                if [ "$password" == "" ]; then
                    msgError "\nPlease enter user password!"
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

                # Confugure environment PATH
                if ! grep -q 'composer' /home/$username/.bashrc ; then
                    echo 'export PATH=$PATH:$HOME/.config/composer/vendor/bin' >> "/home/$username/.bashrc"
                fi
                if ! grep -q 'yarn' /home/$username/.bashrc ; then
                    echo 'export PATH=$PATH:$HOME/.yarn/bin' >> "/home/$username/.bashrc"
                fi

                # Composer environment
                if [ -x "$(command -v composer)" ]; then
                    echo && read -ep "Configure Composer environment?             y/n : " -i "y" answer
                    if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
                        msgInfo "\nConfiguring Composer environment.."
                        runuser -l $username -c 'composer global require hirak/prestissimo --quiet'
                    fi
                fi

                # Nodejs environment
                if [ -x "$(command -v npm)" ]; then
                    echo && read -ep "Configure NodeJS environment?               y/n : " -i "y" answer
                    if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
                        msgInfo "\nConfiguring NodeJS environment.."
                        runuser -l $username -c 'sudo npm i -g ghost-cli@latest &>${logInstall}'
                    fi
                fi

                echo -e "${blue}\nUser ${red}$username${nocolor}${blue} has been created!${nocolor}"
            else
                msgError "Failed to add a user!"
            fi
            break
        fi
    done
}

perl -pi -e 's#(.*sudo.*ALL=)(.*)#${1}(ALL) NOPASSWD:ALL#' /etc/sudoers
[[ $(cat /etc/group  | grep -c webmaster) -eq 1 ]] || groupadd -g 3000 webmaster
[[ $(cat /etc/passwd | grep -c webmaster) -eq 1 ]] || useradd -u 3000 -s /usr/sbin/nologin -d /bin/null -g webmaster webmaster
read -ep "Create new system user?                     y/n : " -i "n" answer
[[ "${answer,,}" =~ ^(yes|y)$ ]] && createNewUser && echo

# Configure Timezone
#-----------------------------------------------------------------------------------------
read -ep "Please specify time zone                        : " -i "Asia/Jakarta" timezone
# [[ $(which ntp) -ne 0 ]] && apt purge -yqq ntp ntpdate &>${logInstall}
# timedatectl set-ntp true &>${logInstall}
timedatectl set-timezone $timezone &>${logInstall}
# systemctl enable systemd-timesyncd &>${logInstall}
# systemctl restart systemd-timesyncd &>${logInstall}

# SSH server + welcome message
#-----------------------------------------------------------------------------------------
read -ep "Please specify SSH port                         : " -i "22" ssh_port
read -ep "Dou you want to enable root login?       yes/no : " -i "no" ssh_root_login

sed -i "s/#ListenAddress :://" /etc/ssh/sshd_config &>${logInstall}
sed -i "s/[#]*PasswordAuthentication/PasswordAuthentication/" /etc/ssh/sshd_config &>${logInstall}
sed -i "s/[#]*PubkeyAuthentication/PubkeyAuthentication/" /etc/ssh/sshd_config &>${logInstall}
sed -i "s/[#]*ClientAliveInterval/ClientAliveInterval/" /etc/ssh/sshd_config &>${logInstall}
sed -i "s/[#]*AllowTcpForwarding/AllowTcpForwarding/" /etc/ssh/sshd_config &>${logInstall}
sed -i "s/[#]*ClientAliveCountMax/ClientAliveCountMax/" /etc/ssh/sshd_config &>${logInstall}
sed -i "s/[#]*PermitRootLogin/PermitRootLogin/" /etc/ssh/sshd_config &>${logInstall}
sed -i "s/[#]*ListenAddress/ListenAddress/" /etc/ssh/sshd_config &>${logInstall}
sed -i "s/[#]*PermitTunnel/PermitTunnel/" /etc/ssh/sshd_config &>${logInstall}
sed -i "s/[#]*X11Forwarding/X11Forwarding/" /etc/ssh/sshd_config &>${logInstall}
sed -i "s/[#]*StrictModes/StrictModes/" /etc/ssh/sshd_config &>${logInstall}
sed -i "s|\("^PermitRootLogin" * *\).*|\1$ssh_root_login|" /etc/ssh/sshd_config &>${logInstall}
sed -i "s|\("^PasswordAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config &>${logInstall}
sed -i "s|\("^PubkeyAuthentication" * *\).*|\1yes|" /etc/ssh/sshd_config &>${logInstall}
sed -i "s|\("^ClientAliveInterval" * *\).*|\1600|" /etc/ssh/sshd_config &>${logInstall}
sed -i "s|\("^AllowTcpForwarding" * *\).*|\1yes|" /etc/ssh/sshd_config &>${logInstall}
sed -i "s|\("^ClientAliveCountMax" * *\).*|\13|" /etc/ssh/sshd_config &>${logInstall}
sed -i "s|\("^ListenAddress" * *\).*|\10.0.0.0|" /etc/ssh/sshd_config &>${logInstall}
sed -i "s|\("^PermitTunnel" * *\).*|\1yes|" /etc/ssh/sshd_config &>${logInstall}
sed -i "s|\("^X11Forwarding" * *\).*|\1no|" /etc/ssh/sshd_config &>${logInstall}
sed -i "s|\("^StrictModes" * *\).*|\1yes|" /etc/ssh/sshd_config &>${logInstall}
sed -i "s/[#]*Port [0-9]*/Port $ssh_port/" /etc/ssh/sshd_config &>${logInstall}
systemctl restart ssh &>${logInstall}

# SSH welcome message
# hostnameLen=`echo $(hostname -f) | wc -c`
# if (( $hostnameLen >= 15 )); then
#     motdMessage=`curl -s ifconfig.me`
# elif (( $hostnameLen <= 14 )); then
#     motdMessage=`hostname -f`
# else
#     motdMessage=`curl -s ifconfig.me`
# fi
motdMessage=`curl -s ifconfig.me`
echo -e "\n Welcome to:" > /etc/motd
echo -e "$(figlet ' '${motdMessage})\n" >> /etc/motd

# Disable IPv6
#-----------------------------------------------------------------------------------------
read -ep "Do you want to disable IPv6?                y/n : " -i "n" answer
if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
    sed -i "s/ListenAddress :://" /etc/ssh/sshd_config &>${logInstall}
    sed -i "s/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/" /etc/gai.conf &>${logInstall}
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.all.disable_ipv6'     '1' &>${logInstall}
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.default.disable_ipv6' '1' &>${logInstall}
    crudini --set /etc/sysctl.conf '' 'net.ipv6.conf.lo.disable_ipv6'      '1' &>${logInstall}
    echo -e 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 &>${logInstall}
    sysctl -p -q >/dev/null 2>&1
fi

# Sysctl tweak
#-----------------------------------------------------------------------------------------
crudini --set /etc/sysctl.conf '' 'net.ipv4.ip_forward'   '1' &>${logInstall}
crudini --set /etc/sysctl.conf '' 'vm.vfs_cache_pressure' '50' &>${logInstall}
crudini --set /etc/sysctl.conf '' 'vm.swappiness'         '10' &>${logInstall}
sysctl -p -q >/dev/null 2>&1

# Linux SWAP
#-----------------------------------------------------------------------------------------
if [[ $(cat /etc/fstab | grep -c "swapfile") -eq 0 ]]; then
    memoryTotal=`grep MemTotal /proc/meminfo | awk '{print $2}'`
    if (( $memoryTotal >= 2097152 )); then opsi="n"; else opsi="y"; fi
    read -ep "Do you want to setup Linux Swap?            y/n : " -i "$opsi" answer
    if [[ "${answer,,}" =~ ^(yes|y)$ ]] ; then
        read -ep "Enter size of Swap (in megabyte)                : " -i "2048" swap_size
        msgInfo "\nConfiguring Linux SWAP...\n"
        echo "/swapfile  none  swap  sw  0 0" >> /etc/fstab
        dd if=/dev/zero of=/swapfile count=$swap_size bs=1M
        chmod 600 /swapfile && mkswap /swapfile
        swapon /swapfile && swapon --show
    fi
fi
