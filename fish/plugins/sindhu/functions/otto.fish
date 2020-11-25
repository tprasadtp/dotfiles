function __print_otto_step -a msg -d "Wrapper to print in color"
  printf "\e[32m  #›$msg\e[0m\n"
end

function __print_otto_not_found -a msg -d "Wrapper to print not found"
  printf "\e[38;5;220m  ⚠ $msg was not found in PATH.\e[0m\n"
end

function otto -d "Generate completions"
  echo "✈ Generating..."
  if type -q gh
    command gh completion -s fish > $HOME/.local/share/fish/generated_completions/gh.fish
  else
    __print_otto_step "GitHub CLI"
    __print_otto_not_found "gh"
  end

  if type -q starship
    __print_otto_step "starship"
    command starship completions fish > $HOME/.local/share/fish/generated_completions/starship.fish
  else
    __print_otto_not_found "starship"
  end

  if type -q minikube
    __print_otto_step "minikube"
    command minikube completion fish > $HOME/.local/share/fish/generated_completions/minikube.fish
  else
    __print_otto_not_found "minikube"
  end

  if type -q poetry
    __print_otto_step "poetry"
    command poetry completions fish > $HOME/.local/share/fish/generated_completions/poetry.fish
  else
    __print_otto_not_found "poetry"
  end

end
