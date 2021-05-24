#!/usr/bin/env fish
# Disable greeting
set fish_greeting

# Set Profile ID
set --global --export DOT_PROFILE_ID 'hpc'

# Use exa if available
if type -q exa
  set fzf_preview_dir_cmd exa --all --color=always
end

# Starship
if type -q starship
  starship init fish | source
end

# direnv
if type -q direnv
  function __direnv_export_eval --on-event fish_postexec;
    direnv export fish | source;
  end
end

# Umask
umask 077
