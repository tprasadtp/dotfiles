# direnv
if type -q direnv
  function __direnv_export_eval --on-event fish_postexec;
    direnv export fish | source;
  end
else
  echo "♺ Install direnv first! Check http://direnv.net" 2>&1
end
