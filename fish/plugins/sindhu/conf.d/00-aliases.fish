#clear time saver
alias c='clear'
alias e='exit'
alias dl='cd ~/Private/Downloads'
alias pg='ping google.com'
alias pdns='ping 1.1.1.3'
alias greph='history | grep'
alias t='tree -ahC -I .git'
alias disks='df -H -t ext4 -t btrfs -t vfat -t ntfs -t ecryptfs -T'

#restart services
alias nmr='sudo service network-manager restart'
alias rnm='sudo service network-manager restart'

# filter processes
alias pfilter='ps -faux | grep'

# Firewall
alias fws='sudo ufw status numbered'

# APT
alias update='sudo apt update'
alias upgradable='sudo apt list --upgradable'
alias agi='sudo apt install'
alias aptc='sudo apt-get clean && sudo apt-get autoremove'

# Colorful grep cmds
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

## pass options to free
alias meminfo='free -m -l -t'

#disk space
alias diskinfo='df -HT -t ext4 -t vfat -t btrfs -t fuseblk '

#show conns
alias ports='ss --tcp --udp --sctp --raw --processes --resolve'
alias lports='ss --tcp --udp --sctp --raw --processes --resolve --listening'

# Weather and Moon
alias wtr='curl -sSf v2.wttr.in'
alias moon='curl -sSf wttr.in/Moon'
