if string match --regex '3.\d.\d' $FISH_VERSION > /dev/null
    set --export --global NEMO_FISH_SHELL_SUPPORTED true
else
    set --export --global NEMO_FISH_SHELL_SUPPORTED false
end