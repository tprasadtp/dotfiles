# P0.Dependent: 00-fish-override.fish
if test -n "$NEMO_FISH_SHELL_DEBUG_LOAD"
  status --current-filename
end

if test $NEMO_FISH_SHELL_SUPPORTED -eq 1
  if test -d /opt/moab/bin/
    set --export --global MOABHOMEDIR /opt/moab
    set --export --global --append  PERL5LIB $MOABHOMEDIR/lib/perl5
    contains -- $MOABHOMEDIR/bin/ $PATH; or set --append PATH $MOABHOMEDIR/bin/
  end
end