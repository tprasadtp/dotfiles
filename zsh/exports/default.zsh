#!/bin/zsh
#-----------------------------------------------------------------------------
#                        Default  Exports
#-----------------------------------------------------------------------------

#Add Custom Script paths
export PATH="${PATH}:${HOME}/Tools/Android/Sdk/platform-tools:${HOME}/bin:${HOME}/.local/bin"
#-----------------------------------------------------------------------------
#                          GPG * SSH
#-----------------------------------------------------------------------------

GPG_TTY=$(tty)
export GPG_TTY

export SSH_AGENT_PID=""
SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
export SSH_AUTH_SOCK
