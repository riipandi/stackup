#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

NO='\033[0;33m'
OK='\033[0;32m'
NC='\033[0m'

while true; do
    read -ep "Enter username for deployer       : " -i "buddy" username
    if [[ $(cat /etc/passwd | grep -c "$username") -eq 1 ]]; then
        echo -e "${NO}User $username already exists!${NC}"
    else
        password=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-25)
        pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
        useradd -mg sudo -s `which bash` $username -c "Deployer Bot" -p $pass
        if [ $? -eq 0 ] ; then
            read -ep "Enter ssh key for this user       : " sshkey
            HOMEDIR=$(eval echo "~$username")
            mkdir -p $HOMEDIR/.ssh ; chmod 0700 $_
            touch $HOMEDIR/.ssh/${username}_keys ; chmod 0600 $_
            echo $sshkey > $HOMEDIR/.ssh/${username}_keys
            chown -R $username: $HOMEDIR/.ssh
            echo -e "${OK}User ${NO}$username${NC}${OK} with password ${NO}$password${NC} ${OK}has been added to system!${NC}"
        else
            echo -e "${NO}Failed to add a user!${NC}"
        fi
        break
    fi
done

# Setup ssh authentication
touch /etc/ssh/sshd_config
if [[ $(cat /etc/ssh/sshd_config | grep -c "$username") -eq 0 ]]; then
    {
        echo ; echo -e "Match User $username"
        echo -e "\tPasswordAuthentication no"
        echo -e "\tPubkeyAuthentication yes"
        echo -e "\tAuthorizedKeysFile .ssh/${username}_keys"
    } >> /etc/ssh/sshd_config
fi
