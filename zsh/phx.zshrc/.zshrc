#!/bin/zsh
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

if [[ $ZPROFILE_ENABLE == "true" ]]; then
  zmodload zsh/zprof
fi


#-----------------------------------------------------------------------------
#                          ID
#-----------------------------------------------------------------------------

# Config
export DOTFILE_PROFILE_ID="phx"

# Caching stuff
ZSH_CACHE_DIR="$HOME/.zsh/cache/"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
export ZSH_CACHE_DIR

#-----------------------------------------------------------------------------
#                   Generic and Keyboard
#-----------------------------------------------------------------------------

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# don't nice background tasks
setopt NO_BG_NICE
setopt NO_HUP
setopt NO_BEEP
# allow functions to have local options
setopt LOCAL_OPTIONS
# allow functions to have local traps
setopt LOCAL_TRAPS
# add timestamps to history
setopt EXTENDED_HISTORY
setopt PROMPT_SUBST
setopt CORRECT
setopt COMPLETE_IN_WORD
# adds history
setopt APPEND_HISTORY
# don't record dupes in history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt HIST_EXPIRE_DUPS_FIRST

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search


#-----------------------------------------------------------------------------
#                   ZSH Settings
#-----------------------------------------------------------------------------

# Do menu-driven completion.
zstyle ':completion:*' menu select

# completion stuff
autoload -Uz compinit

#-----------------------------------------------------------------------------
#                  Personal Plugins
#-----------------------------------------------------------------------------

# Load Exports
# shellcheck disable=SC1090
source  "${HOME}/.zsh/exports/default.zsh"

# Fuzzy finder stuff
# shellcheck disable=SC1090
source "${HOME}/.zsh/fzf/settings.zsh"
source "${HOME}/.zsh/fzf/completion.zsh"
source "${HOME}/.zsh/fzf/key-bindings.zsh"

# Fancy pants
# shellcheck disable=SC1090
source  "${HOME}/.zsh/plugins/fancy.zsh"

# Ubuntu
# shellcheck disable=SC1090
source  "${HOME}/.zsh/plugins/ubuntu.zsh"

# Go
# shellcheck disable=SC1090
source  "${HOME}/.zsh/plugins/golang.zsh"

fpath+=~/.zsh/completions

if [[ $ZPROFILE_ENABLE == "true" ]]; then
  zprof
fi
