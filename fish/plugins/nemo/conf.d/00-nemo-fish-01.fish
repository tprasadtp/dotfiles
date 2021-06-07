# P0.Dependent: ALL

# Debug Hook
if test -n "$NEMO_FISH_SHELL_DEBUG_LOAD"
  status --current-filename
end

# Check FISH_VERSION
if string match --regex '3.\d.\d' $FISH_VERSION > /dev/null
    set --export --global NEMO_FISH_SHELL_SUPPORTED 1
else
    set --export --global NEMO_FISH_SHELL_SUPPORTED 0
end

# Override path of fish
# Fish on NEMO is "ancient"
if test $NEMO_FISH_SHELL_SUPPORTED -eq 1
    # DO NOT USE fish_add_path here!
    set --export --global NEMO_FISH_SHELL_OVERRIDE 1
    contains -- $HOME/opt/fish/bin/ $PATH; or set --prepend PATH $HOME/opt/fish/bin/
else
  set --export --global NEMO_FISH_SHELL_OVERRIDE 0
  # Display warning once
  if test ! $NEMO_FISH_SHELL_MSG_DISPLAYED -eq 1
    set -gx NEMO_FISH_SHELL_MSG_DISPLAYED 1
    echo "Fish version is not supported! All NEMO modules will be disabled!"
    echo "Please install fish 3.2.0 and above and set FISH_INSTALL_LOCATION in your config!"
    echo ""
  end
end