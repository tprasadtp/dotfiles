#!/usr/bin/env bash
if [ -f ~/.bashrc ]; then
  # Profile name
  export DOTFILE_PROFILE_ID="sindhu"

  #shellcheck disable=SC1090
  source ~/.bashrc
fi
