# VGL
if contains true $NEMO_FISH_SHELL_SUPPORTED
  if test -d /opt/VirtualGL/bin
    contains -- /opt/VirtualGL/bin $PATH; or set --append PATH /opt/VirtualGL/bin
  end
end
