# Override Default path
set --export --global POETRY_HOME $HOME/Tools/poetry

# If installed, add Poetry to PATH
if test -d $HOME/Tools/poetry/bin
  contains -- $HOME/Tools/poetry/bin $PATH; or set --append PATH $HOME/Tools/poetry/bin
end
