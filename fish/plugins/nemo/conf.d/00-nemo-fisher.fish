if test -n "$NEMO_FISH_SHELL_DEBUG_LOAD"
  status --current-filename
end

function _nemo_install --on-event nemo_install
    if not string match --regex '3.\d.\d' $FISH_VERSION
        echo "Fish version is not supported! All NEMO modules will be disabled!"
        echo "Please install fish 3.2.0 and above and set FISH_INSTALL_LOCATION in your config!"
        echo ""
    end
end
