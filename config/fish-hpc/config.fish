#!/usr/bin/env fish

# Set Profile ID
set --global --export DOT_PROFILE_ID 'hpc'
set --global --export FISH_INSTALL_LOCATION $HOME/opt/fish

# Appase starship to show hostname if in a job
if contains nemo (hostname --fqdn)
  if not set -q SSH_CONNECTION
    set --export --global SSH_CONNECTION
  end
end

alias c='clear'
alias e='exit'

# Umask
umask 077
