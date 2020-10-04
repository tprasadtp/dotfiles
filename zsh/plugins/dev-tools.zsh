#!/bin/zsh

# Android
#-----------------------------------------------------------------------------
#                        Default  Exports
#-----------------------------------------------------------------------------

#Add Custom Script paths
export PATH="${PATH}:${HOME}/Android/Sdk/platform-tools:${HOME}/Android/Sdk/build-tools/30.0.2:${HOME}/Android/Sdk/emulator"

#-----------------------------------------------------------------------------
#                          gcloud
#-----------------------------------------------------------------------------

if [[ -z "${CLOUDSDK_HOME}" ]]; then
  search_locations=(
    "/snap/google-cloud-sdk/current"
    "/usr/share/google-cloud-sdk"
    "/usr/lib64/google-cloud-sdk/"
    "/opt/google-cloud-sdk"
  )

  for gcloud_sdk_location in $search_locations; do
    if [[ -d "${gcloud_sdk_location}" ]]; then
      CLOUDSDK_HOME="${gcloud_sdk_location}"
      break
    fi
  done
fi

if (( ${+CLOUDSDK_HOME} )); then
  if (( ! $+commands[gcloud] )); then
    # Only source this if GCloud isn't already on the path
    if [[ -f "${CLOUDSDK_HOME}/path.zsh.inc" ]]; then
      source "${CLOUDSDK_HOME}/path.zsh.inc"
    fi
  fi
  source "${CLOUDSDK_HOME}/completion.zsh.inc"
  export CLOUDSDK_HOME
fi

#-----------------------------------------------------------------------------
#                          Go
#-----------------------------------------------------------------------------

export GOROOT="$HOME/Tools/go"
export PATH="$PATH:$GOROOT/bin"

#-----------------------------------------------------------------------------
#                        Hashicorp
#-----------------------------------------------------------------------------

autoload -U +X bashcompinit && bashcompinit

if [[ $commands[terraform] ]]; then
  complete -o nospace -C terraform terraform
fi

if [[ $commands[vault] ]]; then
  complete -o nospace -C vault vault
fi

if [[ $commands[nomad] ]]; then
  complete -o nospace -C nomad nomad
fi

if [[ $commands[packer] ]]; then
  complete -o nospace -C packer packer
fi


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
