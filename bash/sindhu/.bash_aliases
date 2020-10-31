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

# Execute a kubectl command against all namespaces
ka()
{
  kubectl "$@" --all-namespaces
}

# Apply a YML file
alias ka='kubectl apply -f'

# Drop into an interactive terminal on a container
alias keti='kubectl exec -ti'

# Pod management.
alias kgp='kubectl get pods'
alias kgpw='kgp --watch'
alias kgpwide='kgp -o wide'
alias kep='kubectl edit pods'
alias kdp='kubectl describe pods'
alias kdelp='kubectl delete pods'

# Service management.
alias kgs='kubectl get svc'
alias kgsw='kubectl get svc --watch'
alias kgswide='kubectl get svc -o wide'
alias kes='kubectl edit svc'
alias kds='kubectl describe svc'

alias kgns=' edit namespace'
alias kdns='kubectl describe namespace'

# ConfigMap management
alias kgcm='kubectl get configmaps'
alias kecm='kubectl edit configmap'
alias kdcm='kubectl describe configmap'

# Deployment management.
alias kgd='kubectl get deployment'
alias kgdw='kubectl get deployment --watch'
alias kgdwide='kubectl get deployment -o wide'
alias kdd='kubectl describe deployment'

# Port forwarding
alias kpf="kubectl port-forward"

# Tools for accessing all information
alias kga='kubectl get all'
alias kgaa='kubectl get all --all-namespaces'

# Logs
alias kl='kubectl logs'
alias klf='kubectl logs -f'

# File copy
alias kcp='kubectl cp'

# Node Management
alias kgno='kubectl get nodes'
alias keno='kubectl edit node'
alias kdno='kubectl describe node'

# PVC management.
alias kgpvc='kubectl get pvc'
alias kgpvcw='kgpvc --watch'
alias kepvc='kubectl edit pvc'
alias kdpvc='kubectl describe pvc'
