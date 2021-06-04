# P0.Dependent: ALL
# Self override path of fish

if test -d $FISH_INSTALL_LOCATION
  # DO NOT USE fish_add_path here!
  contains -- $FISH_INSTALL_LOCATION/bin/ $PATH; or set --prepend PATH $FISH_INSTALL_LOCATION/bin/
else
  set --export --global NEMO_FISH_SHELL_SUPPORTED false
end
