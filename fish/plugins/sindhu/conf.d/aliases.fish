#clear time saver
alias c='clear'
alias e='exit'
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

# APT
alias update='sudo apt update'
alias upgradable='sudo apt list --upgradable'
alias agi='sudo apt install'
alias apt-clean='sudo apt-get clean'

# Colorful grep cmds
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

## pass options to free
alias meminfo='free -m -l -t'

#disk space
alias diskinfo='df -H'

## Get server cpu info ##
alias cpuinfo='lscpu'

## get GPU ram on desktop / laptop##
alias gpumeminfo='grep -i --color memory /var/log/Xorg.0.log'

#show open ports
alias ports='netstat -tulanp'

# Weather and Moon
# Custom alias for weather
alias weather='curl v2.wttr.in'

# Custom alias for Moon
alias luna='curl wttr.in/Moon'
alias moon='curl wttr.in/Moon'
