#!/usr/bin/env bash
# ~/.bash-aliases: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
# collection of aliases

# Custom alias for weather
alias weather='curl wttr.in'

#update wallpaper
#alias uwp='python ~/.local/bin/bing-wallpaper/bing.py'

# Colorful grep cmds
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'


## pass options to free ##
alias meminfo='free -m -l -t'

#disk space
alias diskinfo='df -H'

## Get server cpu info ##
alias cpuinfo='lscpu'

## get GPU ram on desktop / laptop##
alias gpumeminfo='grep -i --color memory /var/log/Xorg.0.log'

#show open ports
alias ports='netstat -tulanp'


# if user is not root, pass all commands via sudo #
if [ $UID -ne 0 ]; then
    alias reboot='sudo reboot'
    alias update='sudo apt update'
    alias upgradable='sudo apt list --upgradable'
    alias agi='sudo apt install'
    alias apt-clean='sudo apt-get clean'
    alias dpkg-reconfigure='reconfig'
fi

#clear time saver
alias c=clear
alias e=exit
alias q=exit
alias documents='cd ~/Documents'
alias downloads='cd ~/Downloads'
alias desktop='cd ~/Desktop'
alias music='cd ~/Music'
alias videos='cd ~/Videos'
alias pinggoogle='ping google.com'
alias pingdns='ping 8.8.8.8'
alias ext='gnome-shell-extension-tool'
alias bashrc='gedit ~/.bashrc'
alias greph='history |grep'
alias t='tree -ahC -I .git'

#restart services
alias nmr='sudo service network-manager restart'

# filter processes
alias pfilter='ps -faux | grep'

# Firewall
alias fws='sudo ufw status numbered'

alias nerd-mode='eval "$(starship init bash)"'
