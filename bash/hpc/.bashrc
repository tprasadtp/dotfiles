#!/usr/bin/env bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=20000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm|xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    if [[ ${EUID} == 0 ]] ; then
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\h\[\033[01;34m\] \W \$\[\033[00m\] '
    else
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w \$\[\033[00m\] '
    fi
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h \w \$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  # shellcheck disable=SC2015
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
  # shellcheck source=/dev/null
  . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    # shellcheck source=/dev/null
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    # shellcheck source=/dev/null
    . /etc/bash_completion
  fi
fi

# Disable case sentitive completion
set completion-ignore-case On

# Load aliases early
if [ -f ~/.bash_aliases ]; then
  # shellcheck source=/dev/null
  source ~/.bash_aliases
fi

# Local binaries
export PATH="${PATH}:~/bin:~/.local/bin"

# Add GPG Agent config
# This is skipped in codespaces
# for NEMO, set DOT_PROFILE_USE_HOST_SSH_AGENT=true
if [[ ${CODESPACES} != "true" ]] && \
  [[ $CLOUD_SHELL != "true" ]] && \
  [[ ${DOT_PROFILE_USE_HOST_SSH_AGENT} != "true" ]]; then
  GPG_TTY=$(tty)
  export GPG_TTY
  export SSH_AGENT_PID=""
  SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  export SSH_AUTH_SOCK
fi

# Go {This is only applied if Go is installed using Artemis. See go/arty}
if [[ -d ${HOME}/Tools/go ]]; then
  # Sets GOROOT
  export GOROOT="$HOME/Tools/go"
  # Add Go commands to PATH
  export PATH="$PATH:$GOROOT/bin"
fi

# Fish {This is only applied if fish is installed here}
if [[ -d ${HOME}/opt/fish/bin ]]; then
  # Add to PATH. This WILL Override fish on system!
  export PATH="${HOME}/opt/fish/bin:$PATH"
fi

# Go Settings {This is skipped if go is not installed}
if command -v go > /dev/null; then
  # sets GOPATH
  export GOPATH="$HOME/go"
  # Allow Public from Modules Proxy only and limit private to git
  export GOVCS="private:git,public:off"
fi

# Python
export POETRY_HOME="${HOME}/Tools/poetry"
if [[ -d ${HOME}/Tools/poetry/bin ]]; then
  export PATH="${PATH}:${HOME}/Tools/poetry/bin"
fi

# Rust
export CARGO_HOME="${HOME}/Tools/Rust/cargo"
export RUSTUP_HOME="${HOME}/Tools/Rust/rustup"
if [[ -d ${HOME}/Tools/Rust/cargo/bin ]]; then
  export PATH="${PATH}:${HOME}/Tools/Rust/cargo/bin"
fi

# Miniconda
conda_ws="$(ws_find conda)"
# shellcheck disable=SC2181
if [[ $? -eq 0 ]]; then
    export NEMO_CONDA_PATH="$conda_ws/miniconda3/bin"
    export CONDA_ENVS_PATH="$conda_ws/env"
    export CONDA_PKGS_DIRS="$conda_ws/pkgs"
else
  if [[ -d $HOME/Tools/miniconda3 ]]; then
    export NEMO_CONDA_PATH="$HOME/Tools/miniconda3/bin"
  else
    export NEMO_CONDA_PATH="$HOME/miniconda3/bin"
  fi
fi

export PATH="$NEMO_CONDA_PATH:$PATH"
if command -v conda > /dev/null; then
  #shellcheck source=/dev/null
  source <(conda shell.bash hook)
fi

# These MUST be after conda init because conda will modify PS1
# If not disabled in .condarc

# Snippetizer:DirEnv:Init:Start
if command -v direnv > /dev/null; then
  _direnv_hook() {
    local previous_exit_status=$?;
    eval "$(direnv export bash)";
    return $previous_exit_status;
  };
  if ! [[ "${PROMPT_COMMAND:-}" =~ _direnv_hook ]]; then
    PROMPT_COMMAND="_direnv_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
  fi
fi
# Snippetizer:DirEnv:Init:End

# Snippetizer:Starship:Init:Start
if command -v starship > /dev/null; then
  eval "$(starship init bash)"
  if [[ $(hostname --fqdn) == *"nemo"* ]] && [[ -z $SSH_CONNECTION ]]; then
    # We are on NEMO but in an interactive job,
    # appease starship by setting empty SSH_CONNECTION variable
    export SSH_CONNECTION=""
  fi
fi
# Snippetizer:Starship:Init:End

# Umask
umask 077
