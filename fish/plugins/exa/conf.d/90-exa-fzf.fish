# Use exa if available for fzf preview
if type -q exa
  set fzf_preview_dir_cmd exa --all --color=always
end
