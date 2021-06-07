# P0.Dependent: 00-fish-override.fish

if test -n "$NEMO_FISH_SHELL_DEBUG_LOAD"
  status --current-filename
end

# VGL
if test $NEMO_FISH_SHELL_SUPPORTED -eq 1
  if test -d /opt/VirtualGL/bin
    contains -- /opt/VirtualGL/bin $PATH; or set --append PATH /opt/VirtualGL/bin
  end
end
