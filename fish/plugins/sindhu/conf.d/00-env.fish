#!/usr/bin/env fish


# Add GPG Agent config
# This is skipped in codespaces
# for NEMO, set DOT_PROFILE_USE_HOST_SSH_AGENT=true
function check_if_gpg_ssh_is_needed -a number
    if contains true $CODESPACES
      return 0
  else if contains true $CLOUD_SHELL
      return 0
  else if contains true $DOT_PROFILE_USE_HOST_SSH_AGENT
      return 0
  else
      return 1
  end
end

if check_if_gpg_ssh_is_needed
  set --global --export SSH_AGENT_HANDLER "default"
else
  set --erase SSH_AGENT_PID
  set --global --export SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
  set --global --export SSH_AGENT_HANDLER "gpg"
end

functions --erase __check_if_gpg_ssh_is_needed

# Remove ~/.local/bin and ~/bin if present
set -l user_bin_index (contains -i -- /home/$USER/bin $PATH); and set --erase PATH[$user_bin_index]
set -l user_local_bin_index (contains -i -- /home/$USER/.local/bin $PATH); and set --erase PATH[$user_local_bin_index]

# Golang Tools
if test -d $HOME/Tools/go/bin
  contains -- $HOME/Tools/go/bin $PATH; or set --append PATH $HOME/Tools/go/bin
  set --export --global GOROOT $HOME/Tools/go
end

if type -q go
  set --export --global GOPATH $HOME/go
  contains -- $GOPATH/bin $PATH; or set --append PATH $GOPATH/bin

  set --export --global GOVCS "private:git,public:off"
end

# User Local Binaries
if test -d $HOME/bin
  contains -- $HOME/bin $PATH; or set --append PATH $HOME/bin
end

if test -d $HOME/.local/bin
  contains -- $HOME/.local/bin $PATH; or set --append PATH $HOME/.local/bin
end

# Poetry
if test -d $HOME/.poetry/bin
  contains -- $HOME/.poetry/bin $PATH; or set --append PATH $HOME/.poetry/bin
end

# Docker
if type -q docker
  set --export --global DOCKER_CLI_EXPERIMENTAL enabled
end

# Android Platform Tools
if test -d $HOME/Android/Sdk/platform-tools
  contains -- $HOME/Android/Sdk/platform-tools $PATH; or set --append PATH $HOME/Android/Sdk/platform-tools
end

set --erase fish_user_paths
