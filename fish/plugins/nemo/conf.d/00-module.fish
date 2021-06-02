# P0.Dependent: 99-preload-modules.fish
# https://lmod.readthedocs.io/en/latest/030_installing.html
# on NEMO lmod is installed to /usr/share/lmod
if test -f $HOME/opt/fish/bin
  source /usr/share/lmod/lmod/init/profile.fish
end
