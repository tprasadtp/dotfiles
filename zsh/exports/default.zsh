#!/bin/zsh
#-----------------------------------------------------------------------------
#                        Default  Exports
#-----------------------------------------------------------------------------

#Add Custom Script paths
export PATH="${PATH}:~/Tools/Android/Sdk/platform-tools:~/bin:~/.local/bin"
#-----------------------------------------------------------------------------
#                          GPG * SSH
#-----------------------------------------------------------------------------

GPG_TTY=$(tty)
export GPG_TTY

export SSH_AGENT_PID=""
SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
export SSH_AUTH_SOCK
