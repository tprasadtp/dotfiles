# ws-* Aliases. These map to corresponding ws_functions
if contains true $NEMO_FISH_SHELL_SUPPORTED
    alias ws-ls='ws_list'
    alias ws-find='ws_find'
    alias ws-alloc='ws_allocate'
    alias ws-extend='ws_extend'
    alias ws-register='ws_register'
    alias ws-release='ws_release'
    alias ws-unlock='ws_unlock'
end
