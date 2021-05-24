#!/usr/bin/env bash
# ~/.bash-aliases: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)

# Custom alias for weather
alias weather='curl v2.wttr.in'

# Colorful grep cmds
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

## pass options to free ##
alias meminfo='free -m -l -t'

#disk space
alias diskinfo='df -H -t ext4 -t btrfs -t vfat -t ntfs -t ecryptfs -T'

#show open ports
alias ports='netstat -tulanp'

# if user is not root, pass all commands via sudo #
if [ $UID -ne 0 ]; then
    alias reboot='sudo reboot'
    alias update='sudo apt update'
    alias upgradable='sudo apt list --upgradable'
    alias agi='sudo apt install'
    alias apt-clean='sudo apt-get clean'
fi

#clear time saver
alias c=clear
alias e=exit
alias docs='cd ~/Documents'
alias dl='cd ~/Private/Downloads/'
alias pinggoogle='ping google.com'
alias pingdns='ping 8.8.8.8'
alias greph='history |grep'
alias t='tree -ahC -I .git'

# filter processes
alias pfilter='ps -faux | grep'

# Firewall
alias fws='sudo ufw status numbered'

# Kubernetes
# This command is used a LOT both below and in daily life
alias k=kubectl
