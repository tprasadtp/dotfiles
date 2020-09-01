#!/bin/zsh

# GPG and SSH Stuff

GPG_TTY=$(tty)
export GPG_TTY

export SSH_AGENT_PID=""
SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
export SSH_AUTH_SOCK

# Add .local and ~/bin to PATH
export PATH="${PATH}:${HOME}/bin:${HOME}/.local/bin"
