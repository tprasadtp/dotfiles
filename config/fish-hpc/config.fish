#!/usr/bin/env fish

# Set Profile ID
set --global --export DOT_PROFILE_ID 'hpc'

# Self override path of fish
if test -d $HOME/opt/fish/bin
  contains -- $HOME/opt/fish/bin $PATH; or set --prepend PATH $HOME/.local/bin
end

# Umask
umask 077
