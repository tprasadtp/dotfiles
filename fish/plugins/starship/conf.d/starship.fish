# Starship
if type -q starship
  starship init fish | source
else
  echo "♺ Install starship first! Check http://starship.rs" 2>&1
end
