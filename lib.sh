#!/bin/bash

# shellcheck disable=SC2034
true
# see https://github.com/koalaman/shellcheck/wiki/Directive

############ Variables

# PATH & DIR
RUSTDESK_INSTALL_DIR=/var/lib/rustdesk-server
RUSTDESK_LOG_DIR=/var/log/rustdesk-server
# OS
ARCH=$(uname -m)
# Network
WANIP4=$(curl -s -k -m 5 -4 https://api64.ipify.org)
# Whiptail menus
TITLE="RustDesk - $(date +%Y)"
[ -n "$SCRIPT_NAME" ] && TITLE+=" - $SCRIPT_NAME"
CHECKLIST_GUIDE="Navigate with the [ARROW] keys and (de)select with the [SPACE] key. \
Confirm by pressing [ENTER]. Cancel by pressing [ESC]."
MENU_GUIDE="Navigate with the [ARROW] keys and confirm by pressing [ENTER]. Cancel by pressing [ESC]."

############ Functions

print_text_in_color() {
printf "%b%s%b\n" "$1" "$2" "$Color_Off"
}

msg_box() {
    [ -n "$2" ] && local SUBTITLE=" - $2"
    whiptail --title "$TITLE$SUBTITLE" --msgbox "$1" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3
}

yesno_box_yes() {
    [ -n "$2" ] && local SUBTITLE=" - $2"
    if (whiptail --title "$TITLE$SUBTITLE" --yesno "$1" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
    then
        return 0
    else
        return 1
    fi
}

yesno_box_no() {
    [ -n "$2" ] && local SUBTITLE=" - $2"
    if (whiptail --title "$TITLE$SUBTITLE" --defaultno --yesno "$1" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
    then
        return 0
    else
        return 1
    fi
}

input_box() {
    [ -n "$2" ] && local SUBTITLE=" - $2"
    local RESULT && RESULT=$(whiptail --title "$TITLE$SUBTITLE" --nocancel --inputbox "$1" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
    echo "$RESULT"
}

input_box_flow() {
    local RESULT
    while :
    do
        RESULT=$(input_box "$1" "$2")
        if [ -z "$RESULT" ]
        then
            msg_box "Input is empty, please try again." "$2"
        elif ! yesno_box_yes "Is this correct? $RESULT" "$2"
        then
            msg_box "OK, please try again." "$2"
        else
            break
        fi
    done
    echo "$RESULT"
}

identify_os() {
if [ -f /etc/os-release ]
then
    # freedesktop.org and systemd
    # shellcheck source=/dev/null
    source /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    UPSTREAM_ID=${ID_LIKE,,}

    # Fallback to ID_LIKE if ID was not 'ubuntu' or 'debian'
    if [ "${UPSTREAM_ID}" != "debian" ] && [ "${UPSTREAM_ID}" != "ubuntu" ]
    then
        UPSTREAM_ID="$(echo "${ID_LIKE,,}" | sed s/\"//g | cut -d' ' -f1)"
    fi
elif type lsb_release >/dev/null 2>&1
then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]
then
    # For some versions of Debian/Ubuntu without lsb_release command
    # shellcheck source=/dev/null
    source /etc/os-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]
then
    # Older Debian, Ubuntu, etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSE-release ]
then
    # Older SuSE, etc.
    OS=SuSE
    VER=$(cat /etc/SuSE-release)
elif [ -f /etc/redhat-release ]
then
    # Older Red Hat, CentOS, etc.
    OS=RedHat
    VER=$(cat /etc/redhat-release)
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi
}

purge_linux_package() {
    # Identify which OS it is
    if [ -z "${ID}" ] || [ -z "$OS" ] || [ -z "${UPSTREAM_ID}" ]
    then
        identify_os
    fi
    # Purge based on OS
    if [ "${ID}" = "debian" ] || [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian" ] || [ "${UPSTREAM_ID}" = "ubuntu" ] || [ "${UPSTREAM_ID}" = "debian" ]
    then
        apt-get purge "${1}" -y
        apt-get autoremove -y
    elif [ "$OS" = "CentOS" ] || [ "$OS" = "RedHat" ] || [ "${UPSTREAM_ID}" = "rhel" ] || [ "${OS}" = "Almalinux" ] || [ "${UPSTREAM_ID}" = "Rocky*" ]
    then
        yum purge "${1}" -y
    elif [ "${ID}" = "arch" ] || [ "${UPSTREAM_ID}" = "arch" ]
    then
        pacman -S purge "${1}"
    fi
}

install_linux_package() {
    # Identify which OS it is
    if [ -z "${ID}" ] || [ -z "$OS" ] || [ -z "${UPSTREAM_ID}" ]
    then
        identify_os
    fi

    # Install based on OS
    if [ "${ID}" = "debian" ] || [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian" ] || [ "${UPSTREAM_ID}" = "ubuntu" ] || [ "${UPSTREAM_ID}" = "debian" ]
    then
        apt-get install "${1}" -y
    elif [ "$OS" = "CentOS" ] || [ "$OS" = "RedHat" ] || [ "${UPSTREAM_ID}" = "rhel" ] || [ "${OS}" = "Almalinux" ] || [ "${UPSTREAM_ID}" = "Rocky*" ]
    then
        yum install "${1}" -y
    elif [ "${ID}" = "arch" ] || [ "${UPSTREAM_ID}" = "arch" ]
    then
        pacman -S install "${1}"
    fi
}



## bash colors
# Reset
Color_Off='\e[0m'       # Text Reset

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Underline
UBlack='\e[4;30m'       # Black
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
UYellow='\e[4;33m'      # Yellow
UBlue='\e[4;34m'        # Blue
UPurple='\e[4;35m'      # Purple
UCyan='\e[4;36m'        # Cyan
UWhite='\e[4;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Bold High Intensity
BIBlack='\e[1;90m'      # Black
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIBlue='\e[1;94m'       # Blue
BIPurple='\e[1;95m'     # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\e[0;100m'   # Black
On_IRed='\e[0;101m'     # Red
On_IGreen='\e[0;102m'   # Green
On_IYellow='\e[0;103m'  # Yellow
On_IBlue='\e[0;104m'    # Blue
On_IPurple='\e[0;105m'  # Purple
On_ICyan='\e[0;106m'    # Cyan
On_IWhite='\e[0;107m'   # White
