#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo 'This script must be run as root' ; exit 1 ; fi

PWD=$(dirname "$(readlink -f "$0")")
PARENT=$(dirname "$PWD")

# [[ $(cat /etc/passwd | grep -c "$user") -eq 1 ]] || useradd xxxxxx


CreateNewUser() {
    while true; do
        echo
        read -sp "Enter new user password              : " userpass1
        [ "$userpass1" == "" ] && CreateNewUser
        echo
        read -sp "Enter new user password (again)      : " userpass2
        [ "$userpass1" = "$userpass2" ] && break
    done
    echo
}

read -ep "Create a new user?            yes/no : " -i "yes" createuser
if [[ "${createuser,,}" =~ ^(yes|y)$ ]] ; then
    read -ep "Enter new user fullname              : " -i "Admin Sistem" fullname
    read -ep "Enter new user username              : " -i "admin" username
    CreateNewUser
    useradd -mg sudo -s `which bash` $username -c "$fullname" -p `openssl passwd -1 "$userpass1"`
    SetConfigSetup setup create_user no
fi
