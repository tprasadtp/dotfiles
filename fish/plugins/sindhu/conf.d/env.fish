#!/usr/bin/env fish

# SSH stuff
set --erase SSH_AGENT_PID
set --global --export SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)

# Remove ~/.local/bin and ~/bin if present
set -l user_bin_index (contains -i -- /home/$USER/bin $PATH); and set --erase PATH[$user_bin_index]
set -l user_local_bin_index (contains -i -- /home/$USER/.local/bin $PATH); and set --erase PATH[$user_local_bin_index]

# Golang Tools
if test -d $HOME/Tools/go/bin
  contains -- $HOME/Tools/go/bin $PATH; or set --append PATH $HOME/Tools/go/bin
  set --export --global GOROOT $HOME/Tools/go
end

#
if type -q go
  set --export --global GOPATH $HOME/go
  contains -- $GOPATH/bin $PATH; or set --append PATH $GOPATH/bin

  set --export --global GOVCS private:all,public:off
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

# Android Platform Tools
if test -d $HOME/Android/Sdk/platform-tools
  contains -- $HOME/Android/Sdk/platform-tools $PATH; or set --append PATH $HOME/Android/Sdk/platform-tools
end

set --erase fish_user_paths
