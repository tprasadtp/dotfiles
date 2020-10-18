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
readonly FZF_VERSION="0.23.1"
readonly BAT_VERSION="6.1.1"
readonly DIRENV_VERSION="2.20.0"
readonly STARSHIP_VERSION="0.46.0"
readonly FD_VERSION="8.1.1"

# Default settings
DOT_PROFILE_ID="sindhu"
INSTALL_PREFIX="${HOME}"
LOG_LVL=0

function display_usage()
{
#Prints out help menu
cat <<EOF
$LOGO
Usage: ${GREEN}${SCRIPT} ${BLUE}  [options]${YELLOW}
---------------------------------------------
[-i --install]        [Install dotfiles]
[--codespaces]        [Instal in codespaces mode]
                       Bash, Git, GPG, Fish,
                       direnv, starship, docker,
                       VSCode, Fonts and Poetry. Also,
                       invokes --tools install.
${TEAL}
------------- Exclusive Modes ---------------${PINK}
[-C | --only-config]  [Only install configs]
[-F | --only-fish]    [Only install fish configs]
[-M | --minimal]      [Only install Bash, GPG, Git]
[-B | --bash]         [Only install Bash and starship]
[-X | --bin]          [Only install scripts to ~/bin]
[-t | --tools]        [Install Tools necessary]
                        - direnv, starship
                        - bat,fd and fzf
${TEAL}
------------- Skip Modes --------------------${BLUE}
[-c | --no-config]     [Skip installing all config]
[-e | --minimal-config)[Install only base essential configs,
                        skip extra, usually GUI stuff.]
[-k | --no-fonts)      [Skip installing fonts]
[-w | --no-templates)  [Skip installing templates]
[-f | --no-fish)       [Skip installing all fish shell
                        configs]
${TEAL}
------------- Enable Modes ------------------${NC}
[-x | --bin]          [Install scripts in bin to ~/bin]

${TEAL}
----------- Profile Selector ----------------${NC}
When a profile name is set, and if matching config is found,
they will b used instead of default ones. Profile specific
configs are stored in folder with suffix -[DOT_PROFILE_ID].
${ORANGE}
[-p | --profile]      [Set Profile name]

${TEAL}
----------- Debugging & Help ----------------${VIOLET}
[-v | --verbose]      [Enable verbose loggging]
[-h --help]           [Display this help message]
${NC}
EOF
}

function print_info()
{
  printf "➜ %s \n" "$@"
}

function print_success()
{
  printf "%s✔ %s %s\n" "${GREEN}" "$@" "${NC}"
}

function print_warning()
{
  printf "%s⚠ %s %s\n" "${YELLOW}" "$@" "${NC}"
}

function print_error()
{
   printf "%s✖ %s %s\n" "${RED}" "$@" "${NC}"
}


function print_debug()
{
  if [[ $LOG_LVL -gt 0  ]]; then
    printf "%s⚒ %s %s\n" "${GRAY}" "$@" "${NC}"
  fi
}

function print_notice()
{
  printf "%s★ %s %s\n" "${TEAL}" "$@" "${NC}"
}

function print_step_notice()
{
  printf "%s  ★ %s %s\n" "${TEAL}" "$@" "${NC}"
}

function print_step_error()
{
  printf "%s  ✖ %s %s\n" "${RED}" "$@" "${NC}"
}

function print_step_debug()
{
  if [[ $LOG_LVL -gt 0  ]]; then
    printf "%s  ⚒ %s %s\n" "${GRAY}" "$@" "${NC}"
  fi
}

function print_step_info()
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
  local dest="${2}"

#  echo "SRC : $src"
#  echo "DEST: $dest"
#  echo "CURDIR : $CURDIR"

  if [ -d "${CURDIR}/${src}" ]; then
    if mkdir -p "${INSTALL_PREFIX}/${dest}"; then
      while IFS= read -r -d '' file
      do
        f="$(basename "$file")"
        if ln -sfn "$file" "${INSTALL_PREFIX}/${dest}/${f}"; then
          print_step_debug "Linked : ${f}"
        else
          print_step_error "Linking ${f} failed!"
        fi
      done< <(find "$CURDIR/${src}" -maxdepth 1  -not -name "$(basename "$src")" -not -name '*.md' -not -name '.git' -not -name 'LICENSE'  -not -name '.editorconfig' -print0)
    else
      print_step_error "Failed to create destination : $dest"
    fi # mkdir
    else
      print_step_error "Directory ${src} not found!"
  fi # src check

}


function __link_single_item()
{
  # Liks item to specified destination
  # Arg-1 Input file/directory
  # Arg 2 Output symlink

  local src="${1}"
  local dest_dir
  dest_dir="$(dirname "${INSTALL_PREFIX}/${2}")"

  #	 echo "${skip_base_dir_create}"
  #  echo "SRC : $src"
  #  echo "DEST: $dest"
  #  echo "CURDIR : $CURDIR"

  if [ -f "${CURDIR}/${src}" ]; then
    if mkdir -p "${dest_dir}"; then
      f="$(basename "$src")"
      if ln -sfn "${CURDIR}/${src}" "${dest_dir}/${f}"; then
        print_step_debug "Linked : ${f}"
      else
        print_step_error "Linking ${f} failed!"
      fi
    else
      print_step_error "Failed to create destination : $dest_dir"
    fi # mkdir
  else
    print_step_error "File ${src} not found!"
  fi # src check

}


function __install_config_files()
{
  if [[ $# -lt 2 ]]; then
    print_step_error "Invalid number of arguments "
    exit 21;
  fi

  cfg_dir="$1"
  dest_dir="$2"

  # First check for config specific directory
  if [[ -d $CURDIR/config/$cfg_dir-$DOT_PROFILE_ID ]];then
    print_step_notice "config/${cfg_dir}(${DOT_PROFILE_ID})"

    cfg_dir="${cfg_dir}-${DOT_PROFILE_ID}"
  # If no config specific dirs are found, use default config
  elif [[ -d $CURDIR/config/$cfg_dir ]];then
    print_step_info "config/${cfg_dir}"
  else
    print_step_error "No configs found for ${cfg_dir}"
    exit 21
  fi


  if mkdir -p "$INSTALL_PREFIX"/"$dest_dir"; then
    # destination path is prefixed with INSTALL_PREFIX automatically
    __link_files "config/$cfg_dir" "$dest_dir"
  else
    print_step_error "Failed to create $dest_dir directory."
    print_step_error "$cfg_dir will not be installed!"
  fi
}

function install_tools_handler()
{
  print_info "Installing Required Tools"
  mkdir -p "${INSTALL_PREFIX}/bin"
  mkdir -p vendor/cache

  print_info "Download and Install Starship"
  print_step_info "download"
  curl -sSfL "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz" --output vendor/cache/starship.tar.gz
  print_step_info "checksum"
  curl -sSfL "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz.sha256" --output vendor/cache/starship.tar.gz.sha256
  print_step_info "verify"
  echo "$(cat vendor/cache/starship.tar.gz.sha256) vendor/cache/starship.tar.gz" | sha256sum --quiet -c -
  print_step_info "install"
  tar xzf vendor/cache/starship.tar.gz -C "${INSTALL_PREFIX}/bin"

  print_info "Download and Install direnv"
  curl -sSfL "https://github.com/direnv/direnv/releases/download/v${DIRENV_VERSION}/direnv.linux-amd64" \
    -o "${INSTALL_PREFIX}/bin/direnv"

  print_info "Download and Install sharkdp/bat"
  print_step_info "download"
  curl -sSfL "https://github.com/sharkdp/bat/releases/download/v0.16.0/bat-v0.16.0-x86_64-unknown-linux-musl.tar.gz" \
    --output "vendor/cache/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  print_step_info "extract"
  tar --extract --strip=1 --gzip \
    --file="vendor/cache/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    --directory="${INSTALL_PREFIX}/bin" \
    --wildcards "*bat"

  print_info "Download and Install unegunn/fzf"
  print_step_info "download"
  curl -sSfL "https://github.com/junegunn/fzf-bin/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tgz" \
    --output vendor/cache/fzf-${FZF_VERSION}-linux_amd64.tgz
  print_step_info "extract"
  tar --extract --gzip \
    --file="vendor/cache/fzf-${FZF_VERSION}-linux_amd64.tgz" \
    --directory="${INSTALL_PREFIX}/bin" \
    fzf

  print_info "Download and Install sharkdp/fzf"
  print_step_info "download binary"
  curl -sSfL "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    --output "vendor/cache/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  tar --extract --strip=1 --gzip \
    --file="vendor/cache/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    --directory="${INSTALL_PREFIX}/bin" \
    --wildcards "*fd"

  print_info "Set Permissions"
  print_step_info "direnv"
  chmod 700 "${INSTALL_PREFIX}/bin/direnv"
  print_step_info "starship"
  chmod 700 "${INSTALL_PREFIX}/bin/starship"
  print_step_info "sharkdp/bat"
  chmod 700 "${INSTALL_PREFIX}/bin/bat"
  print_step_info "unegunn/fzf"
  chmod 700 "${INSTALL_PREFIX}/bin/fzf"
  print_step_info "sharkdp/fd"
  chmod 700 "${INSTALL_PREFIX}/bin/fd"
}

function install_fonts_handler()
{
  if [[ $bool_skip_fonts == "true" ]]; then
    print_notice "Skipped installing templates"
  else
    print_notice "Installing fonts"
    if mkdir -p "$INSTALL_PREFIX"/.local/share; then
      if ln -snf "$CURDIR"/fonts "$INSTALL_PREFIX"/.local/share/fonts; then
        print_success "Done"
      else
        print_error "Failed to link fonts to .local/share/fonts"
      fi
    else
      print_error "Failed to create fonts directory. Fonts will not be linked!"
    fi
  fi
}


function install_templates_handler()
{
  if [[ $bool_skip_templates == "true" ]]; then
    print_notice "Skipped installing templates"
  else
    print_notice "Installing templates"
    if mkdir -p "${INSTALL_PREFIX}"/Templates; then
      __link_files "templates" "Templates"
    else
      print_error "Failed to create ~/Templates directory."
      print_error "Templates will not be installed"
    fi
    print_success "Done"
  fi
}


function install_fish_configs_handler()
{
  if [[ $bool_skip_fish == "true" ]]; then
    print_notice "Skipped installing fish configurations"
  else
    print_notice "Install fish configs"
    print_step_info "fisher"
    __link_single_item "fish/fisher/fisher.fish" ".config/fish/functions/fisher.fish"
    __install_config_files "fish" ".config/fish/"
  fi
}


function __install_minimal_config_files_handler()
{
  # Docker
  __install_config_files "docker" ".docker"

  # Starship
  __install_config_files "starship" ".config"

  # Direnv
  __install_config_files "direnv" ".config/direnv"

  # Poetry
  __install_config_files "pypoetry" ".config/pypoetry"
}


function __install_other_config_files_handler()
{
  # Ughh!
  __install_config_files "npm" ""

  # Cobra
  __install_config_files "cobra" ""

  # VS code [Mainly Telemetry stuff]
  __install_config_files "vscode" ".config/Code/User"

  # Font config
  __install_config_files "fonts" ""

  # GNU Radio
  __install_config_files "gnuradio" ".gnuradio"

  # Tilix
  __install_config_files "tilix" ".config/tilix/schemes"

  # MPV
  __install_config_files "mpv" ".config/mpv"
}


function install_config_files_handler()
{
  if [[ $bool_skip_config == "true" ]]; then
    print_notice "Skipped installing configs"
  else
    print_notice "Installing config files"
    __install_minimal_config_files_handler
    if [[ $bool_minimal_config == "true" ]]; then
      print_notice "skipped installing extra stuff"
    else
      print_notice "Installing 'extra' configs"
      __install_other_config_files_handler
    fi
  fi
}


function install_bash_handler()
{
  # Installs only bash
  # .bash_profile
  print_notice "Installing bash configs"
  # First check for config specific directory
  if [[ -d $CURDIR/bash/$DOT_PROFILE_ID ]];then
    print_success "Found profile ${DOT_PROFILE_ID}"
    # bash_profile is just a stub common for all
    print_debug "Installing .bash_profile"
    __link_single_item "bash/.bash_profile" ".bash_profile" "true"
    __link_files "bash/${DOT_PROFILE_ID}" ""
    print_success "Done"
  # If no config specific dirs are found, use default `bash`
  else
    print_error "BASH: no config found!"
    return 2
  fi
}


function install_minimal_wrapper()
{
  print_notice "Installing minimal configs"
  install_bash_handler
  __install_config_files "git" ""
  __install_config_files "gnupg" ".gnupg"
  __install_config_files "starship" ".config"
  __install_config_files "direnv" ".config/direnv"
}


function install_regular_wrapper()
{
  install_bash_handler

  print_notice "Install Git & GPG"
  __install_config_files "git" ""
  __install_config_files "gnupg" ".gnupg"

  install_fish_configs_handler
  install_config_files_handler
  install_fonts_handler
  install_templates_handler
  install_scripts_handler

}


function install_codespaces_wrapper()
{
  print_notice "Codespaces:: Tools"
  install_tools_handler
  print_notice "Codespaces:: Configs"
  __install_config_files "docker" ".docker"
  __install_config_files "direnv" ".config/direnv"
  __install_config_files "vscode" ".config/Code/User"
  print_notice "Codespaces:: Fish"
  install_fish_configs_handler
  print_notice "Codespaces:: Fonts"
  install_fonts_handler
  print_notice "Codespaces:: Bash"
  install_bash_handler
}


function install_scripts_handler()
{
  if [[ $bool_install_bin == "true" ]]; then
    print_warning "Installing scripts to ~/bin is enabled!"
    print_warning "Make sure your PATH is properly setup!"
    __link_files "bin" "bin"
  else
    print_debug "Installing scripts is not enabled"
  fi
}


function main()
{
  #check if no args
  if [[ ${CODESPACES} == "true" ]]; then
    print_warning "Invoking codespaces Install"
    action_install_mode="codespaces"
  else
    if [ $# -lt 1 ]; then
      print_error "No arguments/Invalid number of arguments See usage below."
      display_usage;
      exit 1;
    fi
  fi

  while [ "${1}" != "" ]; do
    case ${1} in
      # Install Modes
      -i | --install)         flag_install="true";;
      --codespaces)           flag_codespaces="true";;
      -C | --only-config)     flag_only_config="true";;
      -F | --only-fish)       flag_only_fish="true";;
      -M | --minimal)         flag_only_minimal="true";;
      -B | --bash)            flag_only_bash="true";;
      -X | --bin)             flag_only_bin="true";bool_install_bin="true";;
      -t | --tools)           flag_only_tools="true";;
      # Skip modes
      -c | --no-config)       readonly bool_skip_config="true";;
      # Minimal config profile. This is different than minimal profile.
      # this *ONLY* applies to configs *NOTHING* else. Mostly used to skip
      # GUI stuff which are not used on HPC and headless systems
      -e | --minimal-config)  readonly bool_minimal_config="true";;
      -k | --no-fonts)        readonly bool_skip_fonts="true";;
      -w | --no-templates)    readonly bool_skip_templates="true";;
      -f | --no-fish)         readonly bool_skip_fish="true";;
      # ENABLE Install binaries,
      # This is special as its inverted bool comapred to others
      -x | --bin)             bool_install_bin="true";;
      # Custom profile [overrides defaults]
      -p | --profile )        shift;DOT_PROFILE_ID="${1}";
                              OVERRIDE_DOT_PROFILE_ID="true";;
      # Debug mode
      -v | --verbose)         LOG_LVL=$(( ++LOG_LVL ));
                              print_debug "Enabled verbose logging";;
      -d | --debug)           INSTALL_PREFIX="${HOME}/Junk";
                              LOG_LVL=$(( ++LOG_LVL ));
                              print_warning "DEBUG mode is active!";
                              print_warning "Files will be installed to ${INSTALL_PREFIX}";
                              mkdir -p "${INSTALL_PREFIX}" || exit 31;;
      # Help and unknown option handler
      -h | --help )           display_usage;exit $?;;
      * )                     print_error "Invalid argument(s). See usage below."
                              display_usage;exit 1;;
    esac
    shift
  done

  # Flag conflict checks

  # install with anything should raise error
  if [[ $flag_install == "true" ]]; then
    if [[ ! -z $flag_codespaces ]] || [[ ! -z $flag_only_config ]] || [[ ! -z $flag_only_fish ]] \
    || [[ ! -z $flag_only_minimal ]] || [[ ! -z $flag_only_bash ]] || [[ ! -z $flag_only_bin ]] \
    ||  [[ ! -z $flag_only_tools ]]; then
      print_error "Incompatible Flags!, -i/install cannot be used with other exclusive actions!"
      exit 10
    else
      print_debug "Setting install mode to regular"
      action_install_mode="regular"
    fi
  else
    print_debug "Unused flag [-i/--install]"
  fi

  # Exclusive codespaces check
  if [[ $flag_codespaces == "true" ]]; then
    if [[ ! -z $flag_install ]] || [[ ! -z $flag_only_config ]] || [[ ! -z $flag_only_fish ]] \
    || [[ ! -z $flag_only_minimal ]] || [[ ! -z $flag_only_bash ]] || [[ ! -z $flag_only_bin ]] \
    ||  [[ ! -z $flag_only_tools ]]; then
      print_error "Incompatible Flags!, --codespaces cannot be used with other exclusive actions!"
      exit 10
    else
      print_debug "Setting install mode to codespaces"
      action_install_mode="codespaces"
    fi
  else
    print_debug "Unused flag [--codespaces]"
  fi

  # Exclusive config check
  if [[ $flag_only_config == "true" ]]; then
    if [[ ! -z $flag_install ]] || [[ ! -z $flag_codespaces ]] || [[ ! -z $flag_only_fish ]] \
    || [[ ! -z $flag_only_minimal ]] || [[ ! -z $flag_only_bash ]] || [[ ! -z $flag_only_bin ]] \
    ||  [[ ! -z $flag_only_tools ]]; then
      print_error "Incompatible Flags!, -C/--only-config cannot be used with other exclusive actions!"
      exit 10
    else
      print_debug "Setting install mode to only_config"
      action_install_mode="only_config"
    fi
  else
    print_debug "Unused flag [-C/--only-config]"
  fi

  # Exclusive fish check
  if [[ $flag_only_fish == "true" ]]; then
    if [[ ! -z $flag_install ]] || [[ ! -z $flag_codespaces ]] || [[ ! -z $flag_only_config ]] \
    || [[ ! -z $flag_only_minimal ]] || [[ ! -z $flag_only_bash ]] || [[ ! -z $flag_only_bin ]] \
    ||  [[ ! -z $flag_only_tools ]]; then
      print_error "Incompatible Flags!, -F/--only-fish cannot be used with other exclusive actions!"
      exit 10
    else
      print_debug "Setting install mode to only_fish"
      action_install_mode="only_fish"
    fi
  else
    print_debug "Unused flag [-F/--only-fish]"
  fi

  # Exclusive minimal check
  if [[ $flag_only_minimal == "true" ]]; then
    if [[ ! -z $flag_install ]] || [[ ! -z $flag_codespaces ]] || [[ ! -z $flag_only_config ]] \
    || [[ ! -z $flag_only_fish ]] || [[ ! -z $flag_only_bash ]] || [[ ! -z $flag_only_bin ]] \
    ||  [[ ! -z $flag_only_tools ]]; then
      print_error "Incompatible Flags!, -M/--minimal cannot be used with other exclusive actions!"
      exit 10
    else
      print_debug "Setting install mode to minimal"
      if [[ $OVERRIDE_DOT_PROFILE_ID != "true" ]]; then
        print_debug "No profile overrides selected, choosing minimal profile"
        DOT_PROFILE_ID="minimal"
      fi
      action_install_mode="minimal"
    fi
  else
    print_debug "Unused flag [-M/--minimal]"
  fi

  # Exclusive bash check
  if [[ $flag_only_bash == "true" ]]; then
    if [[ ! -z $flag_install ]] || [[ ! -z $flag_codespaces ]] || [[ ! -z $flag_only_config ]] \
    || [[ ! -z $flag_only_fish ]] || [[ ! -z $flag_only_minimal ]] || [[ ! -z $flag_only_bin ]] \
    ||  [[ ! -z $flag_only_tools ]]; then
      print_error "Incompatible Flags!, -B/--only-bash cannot be used with other exclusive actions!"
      exit 10
    else
      print_debug "Setting install mode to only_bash"
      action_install_mode="only_bash"
    fi
  else
    print_debug "Unused flag [-B/--only-bash]"
  fi

  # Exclusive bin check
  if [[ $flag_only_bin == "true" ]]; then
    if [[ ! -z $flag_install ]] || [[ ! -z $flag_codespaces ]] || [[ ! -z $flag_only_config ]] \
    || [[ ! -z $flag_only_fish ]] || [[ ! -z $flag_only_minimal ]] || [[ ! -z $flag_only_bash ]] \
    ||  [[ ! -z $flag_only_tools ]]; then
      print_error "Incompatible Flags!, -X/--only-bin cannot be used with other exclusive actions!"
      exit 10
    else
      print_debug "Setting install mode to only_bin"
      action_install_mode="only_bin"
    fi
  else
    print_debug "Unused flag [-X/--only-bin]"
  fi

  # Exclusive tools check
  if [[ $flag_only_tools == "true" ]]; then
    if [[ ! -z $flag_install ]] || [[ ! -z $flag_codespaces ]] || [[ ! -z $flag_only_config ]] \
    || [[ ! -z $flag_only_fish ]] || [[ ! -z $flag_only_minimal ]] || [[ ! -z $flag_only_bash ]] \
    ||  [[ ! -z $flag_only_bin ]]; then
      print_error "Incompatible Flags!, -t/--tools cannot be used with other exclusive actions!"
      exit 10
    else
      print_debug "Setting install mode to only_tools"
      action_install_mode="only_tools"
    fi
  else
    print_debug "Unused flag [-t/--tools]"
  fi



  if [[ ! -z $action_install_mode ]]; then
    print_debug "Install mode is set to ${action_install_mode}"
    # Handle install modes
    case ${action_install_mode} in
      # Install All Mode
      regular)        install_regular_wrapper;;
      codespaces)     install_codespaces_wrapper;;
      minimal)        install_minimal_wrapper;;
      only_config)    install_config_files_handler;;
      only_fish)      install_fish_configs_handler;;
      only_bash)      install_bash_handler;;
      only_bin)       install_scripts_handler;;
      only_tools)     install_tools_handler;;
      * )             print_error "Internal Error! Unknown action_install_mode !";exit 127;;
    esac
  else
    print_error "Install mode is not set!!"
    print_error "Did you pass -i/--install or specify any other actions?"
    display_usage;
    exit 10
  fi # install_mode check

  print_debug "Exiting script"
}

#
# install_fish_configs_handler "$@"
main "$@"
