#!/bin/zsh
#----------------------------------------------------------
#                Kubernetes
#----------------------------------------------------------

# if [[ $commands[kubectl] ]]; then
#   #shellcheck disable=SC1090
#   source <(kubectl completion zsh)
#   alias k=kubectl
#   complete -F __start_kubectl k
# fi

if [[ $+commands[kubectl] ]]; then
    __KUBECTL_COMPLETION_FILE="${ZSH_CACHE_DIR}/kubectl_completion"

    if [[ ! -f $__KUBECTL_COMPLETION_FILE ]]; then
        kubectl completion zsh >! $__KUBECTL_COMPLETION_FILE
    fi

    if [[ -f $__KUBECTL_COMPLETION_FILE ]]; then
        source $__KUBECTL_COMPLETION_FILE
        alias k=kubectl
        complete -F __start_kubectl k
    fi

    unset __KUBECTL_COMPLETION_FILE
fi

#----------------------------------------------------------
#                Helm
#----------------------------------------------------------

if [[ $commands[helm] ]]; then
  #shellcheck disable=SC1090
  source <(helm completion zsh)
fi

#----------------------------------------------------------
#                Minikube
#----------------------------------------------------------

if [[ $commands[minikube] ]]; then
  #shellcheck disable=SC1090
  source <(minikube completion zsh)
fi
