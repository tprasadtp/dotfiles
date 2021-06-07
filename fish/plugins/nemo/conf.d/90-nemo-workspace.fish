# P0.Dependent: 00-fish-override.fish

if test -n "$NEMO_FISH_SHELL_DEBUG_LOAD"
  status --current-filename
end

# ws-* Aliases. These map to corresponding ws_functions
if test $NEMO_FISH_SHELL_SUPPORTED -eq 1
    alias ws-ls='ws_list'
    alias ws-find='ws_find'
    alias ws-alloc='ws_allocate'
    alias ws-extend='ws_extend'
    alias ws-register='ws_register'
    alias ws-release='ws_release'
    alias ws-unlock='ws_unlock'
end
