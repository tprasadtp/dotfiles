set conda_ws (ws_find conda)
if test $status -eq 0
    set conda_install_path $conda_ws/miniconda3/bin
    set -gx CONDA_ENVS_PATH "$conda_ws/env"
    set -gx CONDA_PKGS_DIRS "$conda_ws/pkgs"
else
  if test -d $HOME/Tools/miniconda3
    set conda_install_path $HOME/Tools/miniconda3/bin
  else
    set conda_path $HOME/miniconda3/bin
  end
end

contains -- $conda_install_path $PATH; or set --prepend PATH $conda_install_path

if type -q conda
  conda shell.fish hook | source
end
