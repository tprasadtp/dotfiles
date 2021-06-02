# Poetry
if test -d $HOME/.poetry/bin
  contains -- $HOME/.poetry/bin $PATH; or set --append PATH $HOME/.poetry/bin
end
