#!/usr/bin/env bash
#  Copyright (c) 2018-2020. Prasad Tengse
#

# Installs dotfiles
# Probably this script is shitty and  specific to my setup.
# More generic solutions would be to use one of the tools mentioned in.
# https://wiki.archlinux.org/index.php/Dotfiles#Tools
# But most of them require Perl or python. Though
# most systems have those installed by default, I wanted something
# which was dependent only on bash

set -o pipefail

#Constants
readonly SCRIPT=$(basename "$0")
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
readonly CURDIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
readonly LOGO="   [0;1;31;91m_[0;1;33;93m__[0m       [0;1;35;95m_[0;1;31;91m_[0m  [0;1;33;93m_[0;1;32;92m__[0;1;36;96m__[0m [0;1;34;94m_[0;1;35;95m_[0m
  [0;1;33;93m/[0m [0;1;32;92m_[0m [0;1;36;96m\_[0;1;34;94m__[0m  [0;1;31;91m/[0m [0;1;33;93m/_[0;1;32;92m/[0m [0;1;36;96m__[0;1;34;94m(_[0;1;35;95m)[0m [0;1;31;91m/_[0;1;33;93m_[0m [0;1;32;92m__[0;1;36;96m_[0m
 [0;1;33;93m/[0m [0;1;32;92m/[0;1;36;96m/[0m [0;1;34;94m/[0m [0;1;35;95m_[0m [0;1;31;91m\/[0m [0;1;33;93m_[0;1;32;92m_/[0m [0;1;36;96m_[0;1;34;94m//[0m [0;1;35;95m/[0m [0;1;31;91m/[0m [0;1;33;93m-[0;1;32;92m_|[0;1;36;96m_-[0;1;34;94m<[0m
[0;1;32;92m/_[0;1;36;96m__[0;1;34;94m_/[0;1;35;95m\_[0;1;31;91m__[0;1;33;93m/\[0;1;32;92m__[0;1;36;96m/_[0;1;34;94m/[0m [0;1;35;95m/_[0;1;31;91m/_[0;1;33;93m/\[0;1;32;92m__[0;1;36;96m/_[0;1;34;94m__[0;1;35;95m/[0m
"

# Define direnv, bat, fzf, fd versions
readonly FZF_VERSION="0.24.4"
readonly BAT_VERSION="0.17.1"
readonly DIRENV_VERSION="2.23.1"
readonly STARSHIP_VERSION="0.46.2"
readonly FD_VERSION="8.2.1"
# MUST USE HASH
readonly FISHER_VERSION="eab5c67f0b709dee051ac3e9ca0d51c071f712e0"

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
[-i --install]          [Install dotfiles]
[--codespaces]          [Instal in codespaces mode]
                         Bash, Git, GPG, Fish,
                         direnv, starship, docker,
                         VSCode, Fonts and Poetry. Also,
                         invokes --tools installation.
[--cloudshell]          [Installs minmal bash, direnv, starship,
                         python and git configs. Also installs
                         direnv and starship with cloudshell profile.
                         This flag cannot be used with custom profiles]
${NC}
---------------- Exclusive ------------------${PINK}
[-C | --only-config]    [Only install configs]
[-F | --only-fish]      [Only install fish configs]
[-B | --only-bash]      [Only install Bash and starship]
[-X | --only-bin]       [Only install scripts to ~/bin]
[-W | --only-walls]     [Only install wallpapers]
[-M | --minimal]        [Only install Bash, GPG, Git]
[-t | --tools]          [Install Tools necessary]
                          - direnv, starship
                          - bat,fd and fzf${NC}
----------------- Skip ----------------------${BLUE}
[-c | --no-config]      [Skip installing all config]
[-e | --minimal-config) [Install only base essential configs,
                         skip extra, usually GUI stuff.]
[-k | --no-fonts)       [Skip installing fonts]
[-j | --no-templates)   [Skip installing templates]
[-f | --no-fish)        [Skip installing all fish shell
                        configs]${NC}
---------------- Addons ----------------------${TEAL}
[-x | --bin]            [Install scripts in bin to ~/bin]
[-w | --wallpapers]     [Install wallpaper collection]
${NC}
------------ Profile Selector ----------------
When a profile name is set, and if matching config is found,
they will be used instead of default ones. Profile specific
configs are stored in folder with suffix -{ProfileName}.

- Fonts, wallpapers & scripts do not support this!
- If profile specific settings are not found,
  defaults are used.
${ORANGE}
[-p | --profile]        [Set Profile name]${NC}

----------- Debugging & Help ----------------${GRAY}
[-v | --verbose]        [Enable verbose loggging]
[--test]                [Installs to ~/Junk instead of ~]
[-h --help]             [Display this help message]${NC}
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

  # Item to be linked is a file
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
  curl -sSfL "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-musl.tar.gz" --output vendor/cache/starship.tar.gz
  log_step_info "download (checksum)"
  curl -sSfL "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-musl.tar.gz.sha256" --output vendor/cache/starship.tar.gz.sha256
  log_step_info "verify (checksum)"
  if echo "$(cat vendor/cache/starship.tar.gz.sha256) vendor/cache/starship.tar.gz" | sha256sum --quiet -c -; then
    log_step_success "checksums verified"
    log_step_info "install"
    tar xzf vendor/cache/starship.tar.gz -C "${INSTALL_PREFIX}/bin"

    log_step_info "permissions"
    chmod 700 "${INSTALL_PREFIX}/bin/starship"
  else
    log_step_error "cecksum verification failed!"
  fi
}

function __install_tools_subtask_direnv()
{
  __install_tools_subtask_starship
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
  tar --extract --strip=1 --gzip \
    --file="vendor/cache/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    --directory="${INSTALL_PREFIX}/bin" \
    --wildcards "*bat"

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
    tar --extract --gzip \
      --file="vendor/cache/fzf-${FZF_VERSION}-linux_amd64.tar.gz" \
      --directory="${INSTALL_PREFIX}/bin" \
      fzf

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
  tar --extract --strip=1 --gzip \
    --file="vendor/cache/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    --directory="${INSTALL_PREFIX}/bin" \
    --wildcards "*fd"

  log_step_info "permissions"
  chmod 700 "${INSTALL_PREFIX}/bin/fd"
}

function install_tools_handler()
{
  log_info "Installing Required Tools"
  __install_tools_subtask_prepare_dirs

  __install_tools_subtask_direnv
  __install_tools_subtask_starship
  __install_tools_subtask_bat
  __install_tools_subtask_fd
  __install_tools_subtask_fzf
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
  local fisher_plugin_file fish_config_dir

  fisher_plugin_file="${INSTALL_PREFIX}/.config/fish/functions/fisher.fish"
  fish_config_dir="${INSTALL_PREFIX}/.config/fish"

  log_step_info "install fisher@${FISHER_VERSION}"

  log_step_debug "create base functions directory"
  if mkdir -p "${fish_config_dir}/functions"; then
    log_step_debug "done"
  else
    log_step_error "failed to create ${fish_config_dir}/functions"
  fi

  log_step_info "downloading fisher"
  if curl -sfL \
    "https://raw.githubusercontent.com/jorgebucaran/fisher/${FISHER_VERSION}/fisher.fish" \
    --output "${fisher_plugin_file}"; then
    log_step_success "done"
  else
    log_step_error "failed to install fisher!"
    log_step_notice "to fix this problem by run,"
    log_step_notice "curl -sL git.io/fisher | source && fisher install jorgebucaran/fisher@${FISHER_VERSION}"
  fi
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
      # we used to vendor fisher but its no longer necessary.
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
      # we will have to install fisher manaually.
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

  # Docker
  __install_config_files "docker" ".docker"

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
  # Ughh!
  __install_config_files "npm" ""

  # Cobra
  __install_config_files "cobra" ""

  # VS code
  __install_config_files "vscode" ".config/Code/User"
  __install_config_files "vscode/snippets" ".config/Code/User/snippets"


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

  # Poetry
  __install_config_files "pypoetry" ".config/pypoetry"

  # ansible
  __install_config_files "ansible" ""

  log_notice "Cloushell:: Bash"
  install_bash_handler
}

function install_codespaces_wrapper()
{
  log_notice "Codespaces:: Tools"
  install_tools_handler
  log_notice "Codespaces:: Configs[Min]"

  __install_config_files_handler
  log_notice "Codespaces:: Fish"
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
      -i | --install)         flag_install="true";;
      --codespaces)           flag_codespaces="true";;
      --cloudshell)           flag_cloudshell="true";DOT_PROFILE_ID="cloudshell";;
      # Only modes
      -C | --only-config)     flag_only_config="true";;
      -F | --only-fish)       flag_only_fish="true";;
      -B | --only-bash)       flag_only_bash="true";;
      -X | --only-bin)        flag_only_bin="true";bool_install_bin="true";;
      -W | --only-walls)      flag_only_walls="true";bool_install_walls="true";;
      -M | --minimal)         flag_only_minimal="true";;
      -t | --tools)           flag_only_tools="true";;
      # Skip modes
      -c | --no-config)       readonly bool_skip_config="true";;
      # Minimal config profile. This is different than minimal profile.
      # this *ONLY* applies to configs *NOTHING* else. Mostly used to skip
      # GUI stuff which are not used on HPC and headless systems
      -e | --minimal-config)  readonly bool_minimal_config="true";;
      -k | --no-fonts)        readonly bool_skip_fonts="true";;
      -j | --no-templates)    readonly bool_skip_templates="true";;
      -f | --no-fish)         readonly bool_skip_fish="true";;
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
                              LOG_LVL="2";
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

  # cloudshell MUST use profile cloudshell
  if [[ $flag_cloudshell == "true" ]] && [[ $DOT_PROFILE_ID != "cloudshell" ]]; then
    log_error "--cloudshell option MUST use profile cloudshell!!"
    exit 20
  fi

  if [[ $OVERRIDE_DOT_PROFILE_ID == "true" ]] && [[ -z $DOT_PROFILE_ID ]]; then
    log_error "Profile specified is empty!"
    exit 10
  else
    log_notice "Using profile ($DOT_PROFILE_ID)"
  fi


  # install with anything should raise error
  if [[ $flag_install == "true" ]]; then
    if [[ -n $flag_codespaces ]] || [[ -n $flag_cloudshell ]] || [[ -n $flag_only_config ]] || [[ -n $flag_only_fish ]] \
    || [[ -n $flag_only_minimal ]] || [[ -n $flag_only_bash ]] || [[ -n $flag_only_bin ]] \
    ||  [[ -n $flag_only_bin ]] || [[ -n $flag_only_walls ]]; then
      log_error "Incompatible Flags!, -i/install cannot be used with other exclusive actions!"
      exit 10
    else
      log_debug "Setting install mode to regular"
      action_install_mode="regular"
    fi
  else
    log_debug "Unused flag [-i/--install]"
  fi

  # Exclusive codespaces check
  if [[ $flag_codespaces == "true" ]]; then
    if [[ -n $flag_install ]] || [[ -n $flag_cloudshell ]] || [[ -n $flag_only_config ]] || [[ -n $flag_only_fish ]] \
    || [[ -n $flag_only_minimal ]] || [[ -n $flag_only_bash ]] || [[ -n $flag_only_bin ]] \
    ||  [[ -n $flag_only_bin ]] || [[ -n $flag_only_walls ]]; then
      log_error "Incompatible Flags!, --codespaces cannot be used with other exclusive actions!"
      exit 10
    else
      log_debug "Setting install mode to codespaces"
      action_install_mode="codespaces"
    fi
  else
    log_debug "Unused flag [--codespaces]"
  fi

  # Exclusive cloudshell check
  if [[ $flag_cloudshell == "true" ]]; then
    if [[ -n $flag_install ]] || [[ -n $flag_codespaces ]] || [[ -n $flag_only_config ]] || [[ -n $flag_only_fish ]] \
    || [[ -n $flag_only_minimal ]] || [[ -n $flag_only_bash ]] || [[ -n $flag_only_bin ]] \
    ||  [[ -n $flag_only_bin ]] || [[ -n $flag_only_walls ]]; then
      log_error "Incompatible Flags!, --cloudshell cannot be used with other exclusive actions!"
      exit 10
    else
      log_debug "Setting install mode to cloudshell"
      action_install_mode="cloudshell"
    fi
  else
    log_debug "Unused flag [--cloudshell]"
  fi

  # Exclusive config check
  if [[ $flag_only_config == "true" ]]; then
    if [[ -n $flag_install ]] || [[ -n $flag_codespaces ]] || [[ -n $flag_cloudshell ]] || [[ -n $flag_only_fish ]] \
    || [[ -n $flag_only_minimal ]] || [[ -n $flag_only_bash ]] || [[ -n $flag_only_bin ]] \
    ||  [[ -n $flag_only_bin ]] || [[ -n $flag_only_walls ]]; then
      log_error "Incompatible Flags!, -C/--only-config cannot be used with other exclusive actions!"
      exit 10
    else
      log_debug "Setting install mode to only_config"
      action_install_mode="only_config"
    fi
  else
    log_debug "Unused flag [-C/--only-config]"
  fi

  # Exclusive fish check
  if [[ $flag_only_fish == "true" ]]; then
    if [[ -n $flag_install ]] || [[ -n $flag_codespaces ]] || [[ -n $flag_only_config ]] \
    || [[ -n $flag_only_minimal ]] || [[ -n $flag_only_bash ]] || [[ -n $flag_only_bin ]] \
    ||  [[ -n $flag_only_bin ]] || [[ -n $flag_only_walls ]]; then
      log_error "Incompatible Flags!, -F/--only-fish cannot be used with other exclusive actions!"
      exit 10
    else
      log_debug "Setting install mode to only_fish"
      action_install_mode="only_fish"
    fi
  else
    log_debug "Unused flag [-F/--only-fish]"
  fi

  # Exclusive minimal check
  if [[ $flag_only_minimal == "true" ]]; then
    if [[ -n $flag_install ]] || [[ -n $flag_codespaces ]] || [[ -n $flag_only_config ]] \
    || [[ -n $flag_only_fish ]] || [[ -n $flag_only_bash ]] || [[ -n $flag_only_bin ]] \
    ||  [[ -n $flag_only_bin ]] || [[ -n $flag_only_walls ]]; then
      log_error "Incompatible Flags!, -M/--minimal cannot be used with other exclusive actions!"
      exit 10
    else
      log_debug "Setting install mode to minimal"
      action_install_mode="minimal"
    fi
  else
    log_debug "Unused flag [-M/--minimal]"
  fi

  # Exclusive bash check
  if [[ $flag_only_bash == "true" ]]; then
    if [[ -n $flag_install ]] || [[ -n $flag_codespaces ]] || [[ -n $flag_only_config ]] \
    || [[ -n $flag_only_fish ]] || [[ -n $flag_only_minimal ]] || [[ -n $flag_only_bin ]] \
    ||  [[ -n $flag_only_bin ]] || [[ -n $flag_only_walls ]]; then
      log_error "Incompatible Flags!, -B/--only-bash cannot be used with other exclusive actions!"
      exit 10
    else
      log_debug "Setting install mode to only_bash"
      action_install_mode="only_bash"
    fi
  else
    log_debug "Unused flag [-B/--only-bash]"
  fi

  # Exclusive bin check
  if [[ $flag_only_bin == "true" ]]; then
    if [[ -n $flag_install ]] || [[ -n $flag_codespaces ]] || [[ -n $flag_only_config ]] \
    || [[ -n $flag_only_fish ]] || [[ -n $flag_only_minimal ]] || [[ -n $flag_only_bash ]] \
    ||  [[ -n $flag_only_bin ]] || [[ -n $flag_only_walls ]]; then
      log_error "Incompatible Flags!, -X/--only-bin cannot be used with other exclusive actions!"
      exit 10
    else
      log_debug "Setting install mode to only_bin"
      action_install_mode="only_bin"
    fi
  else
    log_debug "Unused flag [-X/--only-bin]"
  fi

  # Exclusive tools check
  if [[ $flag_only_tools == "true" ]]; then
    if [[ -n $flag_install ]] || [[ -n $flag_codespaces ]] || [[ -n $flag_only_config ]] \
    || [[ -n $flag_only_fish ]] || [[ -n $flag_only_minimal ]] || [[ -n $flag_only_bash ]] \
    ||  [[ -n $flag_only_bin ]] || [[ -n $flag_only_walls ]]; then
      log_error "Incompatible Flags!, -t/--tools cannot be used with other exclusive actions!"
      exit 10
    else
      log_debug "Setting install mode to only_tools"
      action_install_mode="only_tools"
    fi
  else
    log_debug "Unused flag [-t/--tools]"
  fi

  # Exclusive tools check
  if [[ $flag_only_walls == "true" ]]; then
    if [[ -n $flag_install ]] || [[ -n $flag_codespaces ]] || [[ -n $flag_only_config ]] \
    || [[ -n $flag_only_fish ]] || [[ -n $flag_only_minimal ]] || [[ -n $flag_only_bash ]] \
    ||  [[ -n $flag_only_bin ]] || [[ -n $flag_only_tools ]]; then
      log_error "Incompatible Flags!, -W/--only-wallpapers cannot be used with other exclusive actions!"
      exit 10
    else
      log_debug "Setting install mode to only_walls"
      action_install_mode="only_walls"
    fi
  else
    log_debug "Unused flag [-W/--only-wallpapers]"
  fi



  if [[ -n $action_install_mode ]]; then
    log_debug "Install mode is set to ${action_install_mode}"
    # Handle install modes
    case ${action_install_mode} in
      # Install All Mode
      regular)        install_regular_wrapper;;
      codespaces)     install_codespaces_wrapper;;
      cloudshell)     install_cloudshell_wrapper;;
      minimal)        install_minimal_wrapper;;
      only_config)    install_config_files_handler;;
      only_fish)      install_fish_configs_handler;;
      only_bash)      install_bash_handler;;
      only_bin)       install_scripts_handler;;
      only_tools)     install_tools_handler;;
      only_walls)     install_walls_handler;;
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
