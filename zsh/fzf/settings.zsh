#!/bin/zsh

export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --exclude .git --color=always'
export FZF_DEFAULT_OPTS="--ansi"

# Options to fzf command
export FZF_COMPLETION_OPTS='+c -x'
