#!/bin/zsh
# Fancy pants module
#----------------------------------------------------------
#                direnv
#----------------------------------------------------------

if [[ $commands[direnv] ]]; then

  _direnv_hook() {
    eval "$("direnv" export zsh)";
  }

  typeset -ag precmd_functions;
  if [[ -z ${precmd_functions[(r)_direnv_hook]} ]]; then
    precmd_functions+=_direnv_hook;
  fi
fi

#----------------------------------------------------------
#            starship prompt
#----------------------------------------------------------

if [[ $commands[starship] ]]; then
  # Starship Rust
  eval "$(starship init zsh)"
fi

#----------------------------------------------------------
#          antibody(zsh plugins)
#----------------------------------------------------------


if [[ $commands[antibody] ]]; then
  # Setup antibody
  alias antibody-update='antibody bundle < ~/.zsh/.antibodyrc | tee ~/.zsh/antibody.zsh'

  # shellcheck disable=SC1090
  source ~/.zsh/antibody.zsh
fi
