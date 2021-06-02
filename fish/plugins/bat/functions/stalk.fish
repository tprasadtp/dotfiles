function stalk -a file --description 'A tail so colorful that you will stalk!'
  if type -q bat
    command tail -f $file | bat --paging=never -l log
  else
    echo "♺ Install bat first! Check https://github.com/sharkdp/bat." 2>&1
  end
end
