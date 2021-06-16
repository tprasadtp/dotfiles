# P0.Dependent: 00-fish-override.fish

if test -n "$FISH_SHELL_DEBUG_LOAD"
    printf "%s %s" "(date --rfc-3339=ns)" "(status --current-filename)"

end

# VGL
if test $NEMO_FISH_SHELL_SUPPORTED -eq 1
  if test -d /opt/VirtualGL/bin
    contains -- /opt/VirtualGL/bin $PATH; or set --append PATH /opt/VirtualGL/bin
  end
end
