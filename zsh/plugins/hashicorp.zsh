#!/bin/zsh

# Hashicorp Autocomplete
autoload -U +X bashcompinit && bashcompinit

if [[ $commands[terraform] ]]; then
  complete -o nospace -C terraform terraform
fi

if [[ $commands[vault] ]]; then
  complete -o nospace -C vault vault
fi

if [[ $commands[nomad] ]]; then
  complete -o nospace -C nomad nomad
fi

if [[ $commands[packer] ]]; then
  complete -o nospace -C packer packer
fi
