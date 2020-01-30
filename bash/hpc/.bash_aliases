#!/usr/bin/env bash
# ~/.bash-aliases: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
# collection of aliases

# Colorful grep cmds
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

#show open ports
alias ports='netstat -tulanp'

#clear time saver
alias c=clear
alias e=exit
alias pinggoogle='ping google.com'
alias pingdns='ping 8.8.8.8'
alias bashrc='gedit ~/.bashrc'
alias greph='history |grep'

# filter processes
alias pfilter='ps -faux | grep'
