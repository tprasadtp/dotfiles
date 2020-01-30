#!/bin/zsh

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  # shellcheck disable=SC2015
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi


# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'


# Custom alias for weather
alias weather='curl wttr.in'

#update wallpaper


#-----------------------------------------------------------------------------
#                          Custom Fucntions
#-----------------------------------------------------------------------------

rnm()
{
    if [ $UID -ne 0 ]; then
        # shellcheck disable=SC2033
        sudo service network-manager restart \
            && echo "$(tput setaf 3)network-manager $(tput sgr0)Restarted"
    fi;
}

#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------

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
alias documents='cd ~/Documents'
alias downloads='cd ~/Downloads'
alias desktop='cd ~/Desktop'
alias music='cd ~/Music'
alias videos='cd ~/Videos'
alias pinggoogle='ping google.com'
alias pingdns='ping 8.8.8.8'
alias bashrc='nano ~/.bashrc'
alias greph='history | grep'
alias t='tree -ahC -I .git'

#restart services
alias nmr='sudo service network-manager restart'

# filter processes
alias pfilter='ps -faux | grep'

# Firewall
alias fws='sudo ufw status numbered'
