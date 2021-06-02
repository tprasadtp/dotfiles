# Self override path of fish
if test -d $HOME/opt/fish/bin
  contains -- $HOME/opt/fish/bin $PATH; or set --prepend PATH $HOME/.local/bin
end
