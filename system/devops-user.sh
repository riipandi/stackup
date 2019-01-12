#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

[ -z $ROOT ] && PARENT=$(dirname "$(readlink -f "$0")") || PARENT=$ROOT

NO='\033[0;33m'
OK='\033[0;32m'
NC='\033[0m'

# Switch to another user: sudo -u goku bash -c "whoami"
#-----------------------------------------------------------------------------------------

DEVOPS_UID="669"
DEVOPS_USER="goku"

if [[ $(cat /etc/passwd | grep -c "$DEVOPS_USER") -eq 1 ]]; then
    echo -e "${NO}User already exists, skipping...${NC}"
else
    touch /etc/ssh/sshd_config
    useradd -u $DEVOPS_UID -mg sudo -r -s /bin/sh $DEVOPS_USER
    if [[ $(cat /etc/ssh/sshd_config | grep -c "$DEVOPS_USER") -eq 0 ]]; then
        {
            echo ; echo -e "DenyUsers $DEVOPS_USER"
        } >> /etc/ssh/sshd_config
    fi
    echo -e "${OK}DevOps user has been added to system!${NC}"
fi
