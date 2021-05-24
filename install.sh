#!/bin/bash
#  Copyright (c) 2018-2021. Prasad Tengse
#
# shellcheck disable=SC2155

# Installs dotfiles
# Probably this script is shitty and  specific to my setup.
# More generic solutions would be to use one of the tools mentioned in.
# https://wiki.archlinux.org/index.php/Dotfiles#Tools
# But most of them require Perl or python. Though
# most systems have those installed by default, I wanted something
# which was dependent only on bash
set -o pipefail

#Constants
readonly SCRIPT="$(basename "$0")"
readonly YELLOW=$'\e[38;5;221m'
readonly GREEN=$'\e[38;5;42m'
readonly RED=$'\e[38;5;197m'
readonly PINK=$'\e[38;5;212m'
readonly BLUE=$'\e[38;5;159m'
readonly ORANGE=$'\e[38;5;208m'
readonly TEAL=$'\e[38;5;192m'
readonly VIOLET=$'\e[38;5;219m'
readonly GRAY=$'\e[38;5;246m'
readonly NC=$'\e[0m'
readonly CURDIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
readonly LOGO="   [0;1;31;91m_[0;1;33;93m__[0m       [0;1;35;95m_[0;1;31;91m_[0m  [0;1;33;93m_[0;1;32;92m__[0;1;36;96m__[0m [0;1;34;94m_[0;1;35;95m_[0m
  [0;1;33;93m/[0m [0;1;32;92m_[0m [0;1;36;96m\_[0;1;34;94m__[0m  [0;1;31;91m/[0m [0;1;33;93m/_[0;1;32;92m/[0m [0;1;36;96m__[0;1;34;94m(_[0;1;35;95m)[0m [0;1;31;91m/_[0;1;33;93m_[0m [0;1;32;92m__[0;1;36;96m_[0m
 [0;1;33;93m/[0m [0;1;32;92m/[0;1;36;96m/[0m [0;1;34;94m/[0m [0;1;35;95m_[0m [0;1;31;91m\/[0m [0;1;33;93m_[0;1;32;92m_/[0m [0;1;36;96m_[0;1;34;94m//[0m [0;1;35;95m/[0m [0;1;31;91m/[0m [0;1;33;93m-[0;1;32;92m_|[0;1;36;96m_-[0;1;34;94m<[0m
[0;1;32;92m/_[0;1;36;96m__[0;1;34;94m_/[0;1;35;95m\_[0;1;31;91m__[0;1;33;93m/\[0;1;32;92m__[0;1;36;96m/_[0;1;34;94m/[0m [0;1;35;95m/_[0;1;31;91m/_[0;1;33;93m/\[0;1;32;92m__[0;1;36;96m/_[0;1;34;94m__[0;1;35;95m/[0m
"

# Define direnv, bat, fzf, fd and fisher versions
readonly FZF_VERSION="0.27.0"
readonly FD_VERSION="8.2.1"

readonly BAT_VERSION="0.17.1"
readonly DIRENV_VERSION="2.28.0"

readonly GIT_CHGLOG_VERSION="0.14.2"

if [[ -v ${FISHER_VERSION} ]]; then
  log_error "FISHER_VERSION is a reserved variable!"
  exit 1
fi

# MUST USE HASH
readonly FISHER_VERSION="247b58e0d97c785ef960b88cd07c734d4e92225c"

# Default settings
DOT_PROFILE_ID="sindhu"
INSTALL_PREFIX="${HOME}"
LOG_LVL=0

function option_error()
{
cat <<EOF
$LOGO
${TEAL}See ${SCRIPT} --help for more info.
EOF
}

function display_usage()
{
#Prints out help menu
cat <<EOF
$LOGO
Usage: ${TEAL}${SCRIPT} ${BLUE} [options] ${NC}
${YELLOW}
[-i --install]          Install dotfiles
[--codespaces]          Instal in codespaces mode
                        Includes - Bash, Git, GPG, Fish,
                        direnv, starship, docker, VSCode,
                        Fonts and Poetry. Also, invokes
                        --tools installation.
[--cloudshell]          Installs minmal bash, direnv, starship,
                        python and git configs. Also installs
                        direnv and starship with cloudshell
                        profile. This flag cannot be used with
                        custom profiles
[--hpc]                 HPC mode. Used on HPC clusters.
                        Skipes all GUI stuff.
${NC}
------------------------- Exclusive ------------------------${PINK}
[-C | --only-config]    Only install configs
[-F | --only-fish]      Only install fish configs
[-B | --only-bash]      Only install Bash and starship
[-X | --only-bin]       Only install scripts to ~/bin
[-W | --only-walls]     Only install wallpapers
[-M | --minimal]        Only install Bash, GPG, Git
[-t | --tools]          Installs necessary tools
                        - direnv, starship
                        - bat,fd and fzf
${NC}
----------------------- Skip ------------------------------${BLUE}
[-c | --no-config]      Skip installing all config
[-e | --minimal-config) Install only base essentials
                        skip extra, usually GUI stuff
[-k | --no-fonts)       Skip installing fonts
[-j | --no-templates)   Skip installing templates
[-f | --no-fish)        Skip installing all fish configs
${NC}
-------------------- Skip Tools ---------------------------${VIOLET}
[--skip-<tool>]         Skip installing this tool

- This only applies if --tool or --codespaces is active.
- <tool> can be one of the following: starship,fd,fzf,
  direnv or git-chglog
${NC}
---------------------- Addons ----------------------------${TEAL}
[-x | --bin]            Install scripts in bin to ~/bin
[-w | --wallpapers]     Install wallpaper collectiont
${NC}
------------------ Profile Selector ----------------------
When a profile name is set, and if matching config is found,
they will be used instead of default ones. Profile specific
configs are stored in folder with suffix -{ProfileName}.

- Fonts, wallpapers & scripts do not support this!
- If profile specific settings are not found,
  defaults are used.
${ORANGE}
[-p | --profile]        Set Profile${NC}

----------------- Debugging & Help ----------------------${GRAY}
[-v | --verbose]        Enable verbose loggging
[--test]                Installs to ~/Junk instead of ~
[-h --help]             Display this help message]${NC}
EOF
}

function log_info()
{
  printf "➜ %s \n" "$@"
}

function log_success()
{
  printf "%s✔ %s %s\n" "${GREEN}" "$@" "${NC}"
}

function log_warning()
{
  printf "%s⚠ %s %s\n" "${YELLOW}" "$@" "${NC}"
}

function log_error()
{
   printf "%s✖ %s %s\n" "${RED}" "$@" "${NC}"
}


function log_debug()
{
  if [[ $LOG_LVL -gt 0  ]]; then
    printf "%s• %s %s\n" "${GRAY}" "$@" "${NC}"
  fi
}

function log_notice()
{
  printf "%s• %s %s\n" "${TEAL}" "$@" "${NC}"
}

function log_step_notice()
{
  printf "%s  • %s %s\n" "${TEAL}" "$@" "${NC}"
}

function log_step_error()
{
  printf "%s  ✖ %s %s\n" "${RED}" "$@" "${NC}"
}

function log_step_success()
{
  printf "%s  ✔ %s %s\n" "${GREEN}" "$@" "${NC}"
}

function log_step_debug()
{
  if [[ $LOG_LVL -gt 0  ]]; then
    printf "%s  • %s %s\n" "${GRAY}" "$@" "${NC}"
  fi
}

function log_step_info()
{
  printf "%s  - %s %s\n" "${VIOLET}" "$@" "${NC}"
}

function __link_files()
{
  # Liks files inside a directory to specified destination
  # Arg-1 Input directory
  # Arg 2 Output dir to place symlinks
  # Always .md .git are ignored.
  # This operation is NOT recursive.

  local src="${1}"
  if [[ -z ${2} ]]; then
    local dest="${INSTALL_PREFIX}"
  else
    local dest="${INSTALL_PREFIX}/${2}"
  fi

  # echo "SRC : $src"
  # echo "DEST: $dest"

  if [ -d "${CURDIR}/${src}" ]; then
    if mkdir -p "${dest}"; then

      while IFS= read -r -d '' file
      do
        f="$(basename "$file")"
        # log_step_debug "${dest%/}/${f}"
        __link_single_item_magic_action "$file" "${dest%/}/${f}"
      done< <(find "$CURDIR/${src}" -maxdepth 1 -type f -not -name '*.md' -not -name '.git' -not -name 'LICENSE' -not -name '.editorconfig' -print0)

    else
      log_step_error "Failed to create destination : $dest"
    fi # mkdir
    else
      log_step_error "Directory ${src} not found!"
  fi # src check

}

# I ran out of ideas to name this fucntion
function __link_single_item_magic_action()
{
  local src="${1}"
  local dest="${2}"
  if ln -sfn "${src}" "${dest}"; then
    log_step_debug "${src} ⇢⇢ ${dest}"
  else
    log_step_error "Linking ${src} to ${dest} failed!"
  fi
}


function __link_single_item()
{
  # Liks item to specified destination
  # Arg-1 Input file/directory
  # Arg 2 Output symlink

  local src="${1}"
  local dest_dir dest_item
  dest_dir="$(dirname "${INSTALL_PREFIX}/${2}")"
  dest_item="$(basename "${2}")"

  # log_debug "SRC : $src"
  # log_debug "DEST: $dest_dir/$dest_item"

  # Item to be linked is a file or a dir
  if [[ -d ${CURDIR}/${src} ]] || [[ -f ${CURDIR}/${src} ]]; then
    if mkdir -p "${dest_dir}"; then
      __link_single_item_magic_action "${CURDIR}/${src}" "${dest_dir}/${dest_item}"
    else
      log_step_error "Failed to create destination : $dest_dir"
    fi # mkdir
  else
    log_step_error "File/directory ${src} not found!"
  fi # src check

}


function __install_config_files()
{
  if [[ $# -lt 2 ]]; then
    log_step_error "Invalid number of arguments "
    exit 21;
  fi

  cfg_dir="$1"
  dest_dir="$2"

  # First check for config specific directory
  if [[ -d $CURDIR/config/$cfg_dir-$DOT_PROFILE_ID ]];then
    log_step_notice "config/${cfg_dir} [${DOT_PROFILE_ID}]"

    cfg_dir="${cfg_dir}-${DOT_PROFILE_ID}"
  # If no config specific dirs are found, use default config
  elif [[ -d $CURDIR/config/$cfg_dir ]];then
    log_step_info "config/${cfg_dir}"
  else
    log_step_error "No configs found for ${cfg_dir}"
  fi


  if mkdir -p "$INSTALL_PREFIX"/"$dest_dir"; then
    # destination path is prefixed with INSTALL_PREFIX automatically
    __link_files "config/$cfg_dir" "$dest_dir"
  else
    log_step_error "Failed to create $dest_dir directory."
    log_step_error "$cfg_dir will not be installed!"
  fi
}

function __install_tools_subtask_prepare_dirs()
{
  log_debug "Ensuring dirs are present for tools install"
  mkdir -p "${INSTALL_PREFIX}/bin"
  mkdir -p vendor/cache

}

function __install_tools_subtask_starship()
{
  # MUST have required dirs already
  log_info "Download and Install Starship"
  log_step_info "download (binary)"
  curl -sSfL "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz" --output vendor/cache/starship.tar.gz
  log_step_info "download (checksum)"
  curl -sSfL "https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz.sha256" --output vendor/cache/starship.tar.gz.sha256
  log_step_info "verify (checksum)"
  if echo "$(cat vendor/cache/starship.tar.gz.sha256) vendor/cache/starship.tar.gz" | sha256sum --quiet -c -; then
    log_step_success "checksums verified"
    log_step_info "install"
    if tar xzf vendor/cache/starship.tar.gz -C "${INSTALL_PREFIX}/bin"; then
      log_step_success "OK"
    else
      log_step_error "errored!"
    fi

    log_step_info "permissions"
    chmod 700 "${INSTALL_PREFIX}/bin/starship"
  else
    log_step_error "checksum verification failed!"
  fi
}

function __install_tools_subtask_direnv()
{
  log_info "Download and Install direnv"
  log_step_info "download"
  curl -sSfL "https://github.com/direnv/direnv/releases/download/v${DIRENV_VERSION}/direnv.linux-amd64" \
    -o "${INSTALL_PREFIX}/bin/direnv"
  log_step_info "permissions"
  chmod 700 "${INSTALL_PREFIX}/bin/direnv"

}

function __install_tools_subtask_bat()
{
  log_info "Download and Install sharkdp/bat"
  log_step_info "download"
  curl -sSfL "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    --output "vendor/cache/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  log_step_info "extract"
  if tar --extract --strip=1 --gzip \
    --file="vendor/cache/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    --directory="${INSTALL_PREFIX}/bin" \
    --wildcards "*bat"; then
    log_step_success "OK"
  else
    log_step_error "errored!"
  fi

  log_step_info "permissions"
  chmod 700 "${INSTALL_PREFIX}/bin/bat"
}

function __install_tools_subtask_fzf()
{
  log_info "Download and Install junegunn/fzf"
  log_step_info "download (binary)"
  curl -sSfL "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz" \
    --output "vendor/cache/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
  log_step_info "download (checksum)"
  curl -sSfL "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf_${FZF_VERSION}_checksums.txt" \
    --output "vendor/cache/fzf_${FZF_VERSION}_checksums.txt"
  if (cd vendor/cache && sha256sum -c --status --ignore-missing "fzf_${FZF_VERSION}_checksums.txt"); then
    log_step_success "checksums verified"
    log_step_info "extract"
    if tar --extract --gzip \
      --file="vendor/cache/fzf-${FZF_VERSION}-linux_amd64.tar.gz" \
      --directory="${INSTALL_PREFIX}/bin" \
      fzf; then
      log_step_success "OK"
    else
      log_step_error "errored!"
    fi


    log_step_info "permissions"
    chmod 700 "${INSTALL_PREFIX}/bin/fzf"

  else
    log_step_error "checksum verification failed!"
    log_error "Failed to install fzf"
  fi
}

function __install_tools_subtask_fd()
{
  log_info "Download and Install sharkdp/fd"
  log_step_info "download binary"
  curl -sSfL "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    --output "vendor/cache/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  log_step_info "extract and install"
  if tar --extract --gzip \
      --file vendor/cache/fd-v"${FD_VERSION}"-x86_64-unknown-linux-musl.tar.gz \
      --directory "${INSTALL_PREFIX}"/bin/ \
      --strip=1 \
      --wildcards \
      --no-anchored 'fd'; then
    log_step_success "OK"
  else
    log_step_error "errored!"
  fi

  log_step_info "permissions"
  chmod 700 "${INSTALL_PREFIX}/bin/fd"
}


function __install_tools_subtask_gitchglog()
{
  log_info "Download and Install git-chglog/git-chglog"
  log_step_info "download binary"
  curl -sSfL "https://github.com/git-chglog/git-chglog/releases/download/v${GIT_CHGLOG_VERSION}/git-chglog_${GIT_CHGLOG_VERSION}_linux_amd64.tar.gz" \
    --output "vendor/cache/git-chglog_${GIT_CHGLOG_VERSION}_linux_amd64.tar.gz"
  log_step_info "download (checksum)"
  curl -sSfL "https://github.com/git-chglog/git-chglog/releases/download/v${GIT_CHGLOG_VERSION}/checksums.txt" \
    --output "vendor/cache/git-chglog-${GIT_CHGLOG_VERSION}-checksums.txt"
  if (cd vendor/cache && sha256sum -c --status --ignore-missing "git-chglog-${GIT_CHGLOG_VERSION}-checksums.txt"); then
    log_step_success "checksums verified"
    log_step_info "extract"
    tar --extract --gzip \
      --file="vendor/cache/git-chglog_${GIT_CHGLOG_VERSION}_linux_amd64.tar.gz" \
      --directory="${INSTALL_PREFIX}/bin" \
      --wildcards git-chglog
    log_step_info "permissions"
    chmod 700 "${INSTALL_PREFIX}/bin/git-chglog"

  else
    log_step_error "checksum verification failed!"
    log_error "Failed to install git-chglog"
  fi
}

function install_tools_handler()
{
  log_info "Installing Required Tools"
  __install_tools_subtask_prepare_dirs

  if [[ $bool_tools_skip_direnv != "true" ]]; then
    __install_tools_subtask_direnv
  else
    log_debug "Skipped installing direnv/direnv"
  fi

  if [[ $bool_tools_skip_starship != "true" ]]; then
      __install_tools_subtask_starship
  else
    log_debug "Skipped installing starship/starship"
  fi

  if [[ $bool_tools_skip_bat != "true" ]]; then
    __install_tools_subtask_bat
  else
    log_debug "Skipped installing sharkdp/bat"
  fi

  if [[ $bool_tools_skip_fd != "true" ]]; then
    __install_tools_subtask_fd
  else
    log_debug "Skipped installing sharkdp/fd"
  fi

  if [[ $bool_tools_skip_fzf != "true" ]]; then
    __install_tools_subtask_fzf
  else
    log_debug "Skipped installing junegunn/fzf"
  fi

  if [[ $bool_tools_skip_gitchglog != "true" ]]; then
    __install_tools_subtask_gitchglog
  else
    log_debug "Skipped installing git-chglog/git-chglog"
  fi
}

function install_fonts_handler()
{
  if [[ $bool_skip_fonts == "true" ]]; then
    log_notice "Skipped installing templates"
  else
    log_notice "Installing fonts"
    if mkdir -p "$INSTALL_PREFIX"/.local/share; then
      if ln -snf "$CURDIR"/fonts "$INSTALL_PREFIX"/.local/share/fonts; then
        log_success "Done"
      else
        log_error "Failed to link fonts to .local/share/fonts"
      fi
    else
      log_error "Failed to create fonts directory. Fonts will not be linked!"
    fi
  fi
}


function install_templates_handler()
{
  if [[ $bool_skip_templates == "true" ]]; then
    log_notice "Skipped installing templates"
  else
    log_notice "Installing templates"
    if mkdir -p "${INSTALL_PREFIX}"/Templates; then
      __link_files "templates" "Templates"
    else
      log_error "Failed to create ~/Templates directory."
      log_error "Templates will not be installed"
    fi
    log_success "Done"
  fi
}

function __download_and_install_fisher()
{
  local fisher_inst_status fisher_otto_status
  fisher_inst_status=0
  fisher_otto_status=0

  log_step_info "install fisher@${FISHER_VERSION}"

  if command -v fish > /dev/null; then

    if [[ $INSTALLER_TEST_MODE != "true" ]]; then

      log_step_info "Installing fisher"
      FISHER_URL="https://raw.githubusercontent.com/jorgebucaran/fisher/${FISHER_VERSION}/functions/fisher.fish" \
      fish --private -c "curl -sSfL \$FISHER_URL | source && fisher update"
      fisher_inst_status="$?"

      if [[ -f ${INSTALL_PREFIX}/.config/fish/functions/otto.fish ]]; then
        log_step_info "Otto plugin exits!"
        mkdir -p "$HOME/.local/share/fish/generated_completions"
        fish --private -c "otto"
        fisher_otto_status=$?
      else
        log_error "Otto not found!"
      fi # otto check

      if [[ $fisher_inst_status -ne 0 ]] || [[ $fisher_otto_status -ne 0 ]]; then
        log_step_error "failed to install fisher!"
        log_step_notice "to fix this problem run,"
        log_step_notice "curl -sfL https://raw.githubusercontent.com/jorgebucaran/fisher/${FISHER_VERSION}/functions/fisher.fish | source && fisher install jorgebucaran/fisher@${FISHER_VERSION}"
      else
        log_step_debug "Otto: $fisher_otto_status, Fisher: $fisher_inst_status"
      fi

    else
      log_step_notice "skipped initializing fisher plugins in test/debug mode"
    fi # debug skipper

  else
    log_step_error "fish is not installed!"
  fi # check for fish shell

}


function install_fish_configs_handler()
{
  local fisher_plugin_file
  fisher_plugin_file="${INSTALL_PREFIX}/.config/fish/functions/fisher.fish"

  if [[ $bool_skip_fish == "true" ]]; then
    log_notice "Skipped installing fish configurations"
  else

    log_notice "Install fish configs"

    # Handle fisher upgrade to 4.x
    if [[ -e "${INSTALL_PREFIX}/.config/fish/fishfile" ]]; then
      log_step_notice "upgrade to fish_plugins"
      if rm "${INSTALL_PREFIX}/.config/fish/fishfile"; then
        log_step_success "removed fishfile file"
      else
        log_step_error "failed to delete .config/fish/fishfile"
      fi
    else
      log_step_debug "no need to perform fisher 3.x to 4.x upgrade fixes"
    fi

    # Install configs and plugin settings
    __install_config_files "fish" ".config/fish/"

    # Fisher
    log_step_debug "check if its necessary to install fisher"

    if [[ -f ${fisher_plugin_file} ]]; then
      # fisher file exists no need to reinstall again.
      # updating is done using fisher itself!
      # update the fish_plugins to correct version of fisher and
      # run fisher update
      log_step_notice "fisher is already installed"
    elif [[ -L ${fisher_plugin_file} ]]; then
      # fisher is a symlink.
      # we used to vendor fisher but it is no longer necessary.
      # remove old symlink and install fisher
      log_step_info "remove old symlink to fisher"
      if rm "$fisher_plugin_file"; then
        log_step_success "done"
      else
        log_step_error "Failed to remove symlink"
      fi
      # install fisher
      __download_and_install_fisher

    else
      # there is neither symlink nor fisher.fish file
      # we will have to install fisher manually.
      # we skip installing autocomplete scripts.
      # because once we run fisher update fisher will install them anyways.
      __download_and_install_fisher
    fi

  fi # bool_skip_fish check
}


function __install_config_files_handler()
{
  # Git
  __install_config_files "git" ""

  # GPG
  __install_config_files "gnupg" ".gnupg"

  # Nano
  __install_config_files "nano" ".config/nano"

  # Starship
  __install_config_files "starship" ".config"

  # Direnv
  __install_config_files "direnv" ".config/direnv"

  # Poetry
  __install_config_files "pypoetry" ".config/pypoetry"

  # ansible
  __install_config_files "ansible" ""
}


function __install_other_config_files_handler()
{
  # VS code
  __install_config_files "vscode" ".config/Code/User"
  __install_config_files "vscode/snippets" ".config/Code/User/snippets"

  # Docker
  __install_config_files "docker" ".docker"

  # Font config
  __install_config_files "fonts" ""

  # GNU Radio
  __install_config_files "gnuradio" ".gnuradio"

  # Tilix
  __install_config_files "tilix" ".config/tilix/schemes"

  # MPV
  __install_config_files "mpv" ".config/mpv"

  # Gedit
  __install_config_files "gedit" ".local/share/gedit/styles"
}


function install_config_files_handler()
{
  if [[ $bool_skip_config == "true" ]]; then
    log_notice "Skipped installing configs"
  else
    log_notice "Installing config files"
    __install_config_files_handler
    if [[ $bool_minimal_config == "true" ]]; then
      log_notice "skipped installing extra stuff"
    else
      log_notice "Installing 'extra' configs"
      __install_other_config_files_handler
    fi
  fi
}


function install_bash_handler()
{
  # Installs only bash
  # .bash_profile
  log_notice "Bash configs"
  # First check for config specific directory
  log_step_info "looking for profile"
  if [[ -d $CURDIR/bash/$DOT_PROFILE_ID ]];then
    log_step_success "found profile ${DOT_PROFILE_ID}"
    __link_files "bash/${DOT_PROFILE_ID}" ""
    log_step_success "done"
  # If no config specific dirs are found, use default `bash`
  else
    log_error "BASH: no config found!"
    return 2
  fi
}


function install_minimal_wrapper()
{
  log_notice "Installing minimal configs"
  install_bash_handler
  __install_config_files "git" ""
  __install_config_files "gnupg" ".gnupg"
  __install_config_files "starship" ".config"
  __install_config_files "direnv" ".config/direnv"
}


function install_regular_wrapper()
{
  install_bash_handler
  install_fish_configs_handler
  install_config_files_handler
  install_fonts_handler
  install_templates_handler
  install_scripts_handler
  install_walls_handler
}


function install_cloudshell_wrapper()
{
  log_notice "Cloushell:: Tools"

  __install_tools_subtask_prepare_dirs
  __install_tools_subtask_direnv
  __install_tools_subtask_starship

  log_notice "Cloushell:: Configs"
  # Git
  __install_config_files "git" ""

  # Direnv
  __install_config_files "direnv" ".config/direnv"

  # ansible
  __install_config_files "ansible" ""

  log_notice "Cloushell:: Bash"
  install_bash_handler
}

function install_hpc_wrapper()
{
  log_notice "Installing minimal configs"
  install_bash_handler
  if [[ $bool_skip_config != "true" ]]; then
    __install_config_files_handler
  else
    log_debug "Skipped config install"
  fi

  if [[ $bool_skip_fish != "true" ]]; then
    install_fish_configs_handler
  else
    log_debug "Skipped fish configs"
  fi

  if [[ $bool_install_bin == "true" ]]; then
    log_warning "Installing scripts to ~/bin is enabled!"
    log_warning "Make sure your PATH is properly setup!"
    __link_files "bin" "bin"
    __link_files "bin-hpc" "bin"
  else
    log_debug "Installing scripts is not enabled"
  fi

}

function install_codespaces_wrapper()
{
  log_notice "Codespaces:: Tools"
  install_tools_handler

  log_notice "Codespaces:: Configs[Min]"
  __install_config_files_handler

  log_notice "Codespaces:: Fish"
  if [[ -L ${INSTALL_PREFIX}/Git/dotfiles ]]; then
    log_step_success "Dotfiles symlink to ~/Git/dotfiles already exists!"
  elif [[ -L ${INSTALL_PREFIX}/Git/dotfiles ]]; then
    log_step_warning "There already is a link at ${INSTALL_PREFIX}/Git/dotfiles"
  else
    # Create a symlink from to ${INSTALL_PREFIX}/Git/dotfiles
    # This is necessary to avoid breaking fish plugins
    log_step_info "Fix Fish plugins relative path"
    __link_single_item "" "Git/dotfiles"
  fi
  install_fish_configs_handler

  log_notice "Codespaces:: Fonts"
  install_fonts_handler

  log_notice "Codespaces:: Bash"
  install_bash_handler
}


function install_scripts_handler()
{
  if [[ $bool_install_bin == "true" ]]; then
    log_warning "Installing scripts to ~/bin is enabled!"
    log_warning "Make sure your PATH is properly setup!"
    __link_files "bin" "bin"
  else
    log_debug "Installing scripts is not enabled"
  fi
}

function install_walls_handler()
{
  if [[ $bool_install_walls == "true" ]]; then

    log_notice "Installing wallpapers"
    log_step_info "Installig to ~/Pictures/Wallpapers"
    __link_single_item "walls" "Pictures/Wallapers"

    log_step_info "Applying GNOME wallpaper workaround!"
    __link_single_item "walls" ".cache/gnome-control-center/backgrounds"

  # walls is disabled
  else
    log_debug "Wallpaper installation is disabled"
  fi
}

function main()
{
  #check if no args
  if [[ ${CODESPACES} == "true" ]]; then
    log_warning "Codespaces:: Install"
    action_install_mode="codespaces"
  else
    if [ $# -lt 1 ]; then
      log_error "No arguments specified!"
      option_error;
      exit 1;
    fi
  fi

  while [ "${1}" != "" ]; do
    case ${1} in
      # Install Modes
      -i | --install)         action_install_mode="default";
                              log_info "Using mode: ${action_install_mode}";
                              ((++exclusive_conflicts));
                              ;;
      --codespaces)           action_install_mode="codespaces";
                              log_info "Using mode: ${action_install_mode}";
                              ((++exclusive_conflicts));
                              ;;
      --cloudshell)           action_install_mode="cloudshell";
                              log_info "Using mode: ${action_install_mode}";
                              ((++exclusive_conflicts));
                              ;;
      --hpc)                  action_install_mode="hpc";
                              DOT_PROFILE_ID="hpc";
                              log_info "Using mode: ${action_install_mode}";
                              ((++exclusive_conflicts));
                              ;;
      -C | --only-config)     action_install_mode="only-config";
                              log_info "Using mode: ${action_install_mode}";
                              ((++exclusive_conflicts));
                              ;;
      -F | --only-fish)       action_install_mode="only-fish";
                              log_info "Using mode: ${action_install_mode}";
                              ((++exclusive_conflicts));
                              ;;
      -B | --only-bash)       action_install_mode="only-bash";
                              log_info "Using mode: ${action_install_mode}";
                              ((++exclusive_conflicts));
                              ;;
      -X | --only-scripts)    action_install_mode="only-scripts";
                              bool_install_bin="true";
                              log_info "Using mode: ${action_install_mode}";
                              ((++exclusive_conflicts));
                              ;;
      -W | --only-walls)      action_install_mode="only-walls";
                              bool_install_walls="true";
                              log_info "Using mode: ${action_install_mode}";
                              ((++exclusive_conflicts));
                              ;;
      -M | --minimal)         action_install_mode="minimal";
                              log_info "Using mode: ${action_install_mode}";
                              ((++exclusive_conflicts));
                              ;;
      -t | --tools)           action_install_mode="only-tools";
                              bool_install_bin="true";
                              log_info "Using mode: ${action_install_mode}";
                              ((++exclusive_conflicts));
                              ;;
      # Skip modes
      -c | --skip-config)     readonly bool_skip_config="true";;
      --skip-starship)        readonly bool_tools_skip_starship="true";;
      --skip-direnv)          readonly bool_tools_skip_direnv="true";;
      --skip-bat)             readonly bool_tools_skip_bat="true";;
      --skip-fzf)             readonly bool_tools_skip_fzf="true";;
      --skip-fd)              readonly bool_tools_skip_fd="true";;
      --skip-gitchglog)       readonly bool_tools_skip_gitchglog="true";;

      # Minimal config profile. This is different than minimal profile.
      # this *ONLY* applies to configs *NOTHING* else. Mostly used to skip
      # GUI stuff which are not used on HPC and headless systems
      -e | --minimal-config)  readonly bool_minimal_config="true";;
      -k | --skip-fonts)      readonly bool_skip_fonts="true";;
      -j | --skip-templates)  readonly bool_skip_templates="true";;
      -f | --skip-fish)       readonly bool_skip_fish="true";;

      # ENABLE Extra,
      # These are special as they are inverted bool comapred to other bools
      -x | --bin)             bool_install_bin="true";;
      -w | --wallpapers)      bool_install_walls="true";;
      # Custom profile [overrides defaults]
      -p | --profile )        shift;DOT_PROFILE_ID="${1}";
                              OVERRIDE_DOT_PROFILE_ID="true";;
      # Debug mode
      -v | --verbose)         LOG_LVL="1";
                              log_debug "Enabled verbose logging";;
      -d | --debug | --test)  INSTALL_PREFIX="${HOME}/Junk";
                              INSTALLER_TEST_MODE="true";
                              log_warning "DEBUG mode is active!";
                              log_warning "Files will be installed to ${INSTALL_PREFIX}";
                              mkdir -p "${INSTALL_PREFIX}" || exit 31;;
      # Help and unknown option handler
      -h | --help )           display_usage;exit $?;;
      * )                     log_error "Invalid argument(s). See usage below."
                              option_error;exit 1;;
    esac
    shift
  done

  # Flag conflict checks
  if [[ $exclusive_conflicts -gt 1 ]]; then
    log_error "Exclusive flag conflict!"
    log_error "More than one exclusive flag is used!"
    exit 1
  else
    log_debug "No command conflicts"
  fi

  # hpc MUST use profile cloudshell
  if [[ $action_install_mode == "hpc" ]] && [[ $DOT_PROFILE_ID != "hpc" ]]; then
    log_error "--hpc option MUST use profile hcp!!"
    exit 20
  fi

  if [[ $OVERRIDE_DOT_PROFILE_ID == "true" ]] && [[ -z $DOT_PROFILE_ID ]]; then
    log_error "Profile specified is empty!"
    exit 10
  else
    log_notice "Using profile ($DOT_PROFILE_ID)"
  fi

  if [[ -n $action_install_mode ]]; then
    log_debug "Install mode is set to ${action_install_mode}"
    # Handle install modes
    case ${action_install_mode} in
      # Install All Mode
      default)        install_regular_wrapper;;
      codespaces)     install_codespaces_wrapper;;
      cloudshell)     install_cloudshell_wrapper;;
      hpc)            install_hpc_wrapper;;
      minimal)        install_minimal_wrapper;;
      only-config)    install_config_files_handler;;
      only-fish)      install_fish_configs_handler;;
      only-bash)      install_bash_handler;;
      only-bin)       install_scripts_handler;;
      only-tools)     install_tools_handler;;
      only-walls)     install_walls_handler;;
      * )             log_error "Internal Error! Unknown action_install_mode !";exit 127;;
    esac
  else
    log_error "Install mode is not set!!"
    log_error "Did you pass -i/--install or specify any other actions?"
    option_error;
    exit 10
  fi # install_mode check
}

#
# install_fish_configs_handler "$@"
main "$@"
