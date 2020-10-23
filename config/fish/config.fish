#!/usr/bin/env fish
# Disable greeting
set fish_greeting

# Fish syntax highlighting
set -g fish_color_autosuggestion '555'  'brblack'
set -g fish_color_cancel -r
set -g fish_color_command
set -g fish_color_comment red
set -g fish_color_cwd green
set -g fish_color_cwd_root red
set -g fish_color_end brmagenta
set -g fish_color_error brred
set -g fish_color_escape 'yellow'
set -g fish_color_history_current
set -g fish_color_host normal
set -g fish_color_match --background=blue
set -g fish_color_normal normal
set -g fish_color_operator yellow
set -g fish_color_param cyan
set -g fish_color_quote yellow
set -g fish_color_redirection blue
set -g fish_color_search_match 'bryellow'  '--background=black'
set -g fish_color_selection 'white'  '--bold'  '--background=black'
set -g fish_color_user green
set -g fish_color_valid_path --underline

# Set Profile ID
set --global --export DOT_PROFILE_ID 'sindhu'
