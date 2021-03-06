#!/usr/bin/env fish
# Disable greeting
set fish_greeting

# Add GPG Agent config
# This is skipped in codespaces
# for NEMO, set DOT_PROFILE_SKIP_SSH_CONFIG=true
function enable_setup_gpg_ssh -a number
  if contains true $CODESPACES
      set --expo
      return 0
  else if contains true $CLOUD_SHELL
      return 0
  else if contains true $DOT_PROFILE_SKIP_SSH_CONFIG
      return 0
  else if contains nemo (hostname --fqdn)
      return 0
  else
      return 1
  end
end

if enable_setup_gpg_ssh
  set --erase SSH_AGENT_PID
  set --global --export SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
  set --global --export SSH_AGENT_HANDLER "gpg"
else
  set --global --export SSH_AGENT_HANDLER "default"
end

functions --erase enable_setup_gpg_ssh

# Remove ~/.local/bin and ~/bin if present
set -l user_bin_index (contains -i -- /home/$USER/bin $PATH); and set --erase PATH[$user_bin_index]
set -l user_local_bin_index (contains -i -- /home/$USER/.local/bin $PATH); and set --erase PATH[$user_local_bin_index]

# User Local Binaries
if test -d $HOME/bin
  contains -- $HOME/bin $PATH; or set --append PATH $HOME/bin
end

if test -d $HOME/.local/bin
  contains -- $HOME/.local/bin $PATH; or set --append PATH $HOME/.local/bin
end

set --erase fish_user_paths
