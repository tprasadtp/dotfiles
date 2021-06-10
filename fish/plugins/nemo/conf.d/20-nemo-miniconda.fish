set __conda_ws (ws_find conda)
if test $status -eq 0
    set __conda_path $__conda_ws/miniconda3/bin
else
  if test -d $HOME/Tools/miniconda3
    set __conda_path $HOME/Tools/miniconda3/bin
  else
    set __conda_path $HOME/miniconda3/bin
  end
end

contains -- $__conda_path $PATH; or set --prepend PATH $__conda_path

# conda shell.fish hook | source
# set --erase __conda_path
# set --erase __conda_ws
