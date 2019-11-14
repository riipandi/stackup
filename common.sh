# Color message
#----------------------------------------------------------------------------------
nocolor='\033[0m'
green='\033[0;32m'
red='\033[0;33m'
blue='\033[0;34m'


# Common variables
#----------------------------------------------------------------------------------
osDistro=`echo $(lsb_release -i | cut -d':' -f 2)`
osVersion=`echo $(lsb_release -c | cut -d':' -f 2)`
logFile="/root/stackup-info.log"
logInstall="/tmp/stackup-install.log"
checkCountry=$(wget -qO- ipapi.co/json | grep '"country":' | sed -E 's/.*"([^"]+)".*/\1/')

# Display message
#----------------------------------------------------------------------------------
msgContinue() {
    echo -e "${green}"
    read -p "Press [Enter] to Continue or [Ctrl+C] to Cancel..."
    echo -e "${nocolor}"
}

msgInfo() {
    echo -e "${blue}${1}${nocolor}"
}

msgSuccess() {
    echo -e "${green}${1}${nocolor}"
}

msgError() {
    echo -e "${red}${1}${nocolor}"
}


# Common functions
#----------------------------------------------------------------------------------

# pkgInstall() {}

# pkgUpdate() {}

pkgUpgrade() {
    apt update -qq &>${logInstall}
    apt -yq full-upgrade &>${logInstall}
    apt -y autoremove &>${logInstall}
}

pkgClean() {
    apt -yq autoremove &>${logInstall}
    apt clean &>${logInstall}
}

writeLogInfo () {
    crudini --set ${logFile} '' ${1} ${2}
}
