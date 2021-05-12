#!/usr/bin/env bash
# Copyright (c) 2021. Prasad Tengse
#
# shellcheck disable=SC2155,SC2034

set -o pipefail

# Script Constants
readonly CURDIR="$(cd -P -- "$(dirname -- "")" && pwd -P)"
readonly SCRIPT="$(basename "$0")"
# Default log level (debug logs are disabled)
LOG_LVL=0

# Handle Signals
# trap ctrl-c and SIGTERM
trap ctrl_c_signal_handler INT
trap term_signal_handler SIGTERM

function ctrl_c_signal_handler() {
  log_error "User Interrupt! CTRL-C"
  exit 4
}
function term_signal_handler() {
  log_error "Signal Interrupt! SIGTERM"
  exit 4
}

# Logging Handlers

# Define colors for logging
function define_colors()
{
  readonly YELLOW=$'\e[38;5;214m'
  readonly GREEN=$'\e[38;5;83m'
  readonly RED=$'\e[38;5;197m'
  readonly NC=$'\e[0m'

  # Enhanced colors
  readonly PINK=$'\e[38;5;212m'
  readonly BLUE=$'\e[38;5;81m'
  readonly ORANGE=$'\e[38;5;208m'
  readonly TEAL=$'\e[38;5;192m'
  readonly VIOLET=$'\e[38;5;219m'
  readonly GRAY=$'\e[38;5;250m'
  readonly DARK_GRAY=$'\e[38;5;246m'

  # Flag
  readonly COLORIZED=1
}

function undefine_colors()
{
  # Disable all colors
  readonly YELLOW=""
  readonly GREEN=""
  readonly RED=""
  readonly NC=""

  # Enhanced colors
  readonly PINK=""
  readonly BLUE=""
  readonly ORANGE=""
  readonly TEAL=""
  readonly VIOLET=""
  readonly GRAY=""
  readonly DARK_GRAY=""

  # Flag
  readonly COLORIZED=1
}

# Check for Colored output
if [[ -n ${CLICOLOR_FORCE} ]] && [[ ${CLICOLOR_FORCE} != "0" ]]; then
  # In CI/CD Forces colors
  define_colors
elif [[ -t 1 ]] && [[ -z ${NO_COLOR} ]] && [[ ${TERM} != "dumb" ]] ; then
  # Enables colors if Terminal is interactive and NOCOLOR is not empty
  define_colors
else
  # Disables colors
  undefine_colors
fi

## Check if logs should be written to stderr
## This is useful if script generates an output which can be piped or redirected
if [[ -z ${LOG_TO_STDERR} ]]; then
  LOG_TO_STDERR="false"
fi

# Log functions
function log_info()
{
  if [[ $LOG_TO_STDERR == "true" ]]; then
    printf "• %s \n" "$@" 1>&2
  else
    printf "• %s \n" "$@"
  fi
}

function log_success()
{
  if [[ $LOG_TO_STDERR == "true" ]]; then
    printf "%s• %s %s\n" "${GREEN}" "$@" "${NC}" 1>&2
  else
    printf "%s• %s %s\n" "${GREEN}" "$@" "${NC}"
  fi
}

function log_warning()
{
  if [[ $LOG_TO_STDERR == "true" ]]; then
    printf "%s• %s %s\n" "${YELLOW}" "$@" "${NC}" 1>&2
  else
    printf "%s• %s %s\n" "${YELLOW}" "$@" "${NC}"
  fi
}

function log_error()
{
  if [[ $LOG_TO_STDERR == "true" ]]; then
    printf "%s• %s %s\n" "${RED}" "$@" "${NC}" 1>&2
  else
    printf "%s• %s %s\n" "${RED}" "$@" "${NC}"
  fi
}

function log_debug()
{
  if [[ LOG_LVL -gt 0  ]]; then
    if [[ $LOG_TO_STDERR == "true" ]]; then
      printf "%s• %s %s\n" "${GRAY}" "$@" "${NC}" 1>&2
    else
      printf "%s• %s %s\n" "${GRAY}" "$@" "${NC}"
    fi
  fi
}

function log_notice()
{
  if [[ $LOG_TO_STDERR == "true" ]]; then
    printf "%s• %s %s\n" "${TEAL}" "$@" "${NC}" 1>&2
  else
    printf "%s• %s %s\n" "${TEAL}" "$@" "${NC}"
  fi
}

function log_variable()
{
  local var
  var="$1"
  if [[ ${LOG_LVL} -gt 0  ]]; then
    if [[ $LOG_TO_STDERR == "true" ]]; then
      printf "%s» %-20s - %-10s %s\n" "${GRAY}" "${var}" "${!var}" "${NC}" 1>&2
    else
      printf "%s» %-20s - %-10s %s\n" "${GRAY}" "${var}" "${!var}" "${NC}"
    fi
  fi
}

# Checks if command is available
function has_command() {
  if command -v "$1" >/dev/null; then
    return 0
  else
    return 1
  fi
  return 1
}


function display_usage()
{
#Prints out help menu
cat <<EOF
- Bash script to install shell utilities on machines intended
for remote access.
- Please note that this script will NOT install nerd fonts.
This is because they should be on local machine not remote.
- This is not a replacement for dotfiles installer. This
only installs starship and its auxillary bash files on remote
machine.
- Any shells other than bash are not supported.

Usage: ${TEAL}${SCRIPT} ${BLUE} [options] ${NC}
${VIOLET}
------------------------- Options ------------------------------${NC}
[--install]             Enable Install mode
[--test]                Install to ~/Junk/ prefix
${ORANGE}
---------------- Options with Required Argments-----------------${NC}
[--platform <variant>]  Override platform. This is useful when
                        remote filesystem is mounted over SSH,
                        and remote and host architectures are
                        different.
                        Variant is for format <uname -s>-<uname -m>
${GRAY}
--------------------- Debugging & Help -------------------------${NC}
[-d | --debug]          Enable debug loggging
[--stderr]              Log to stderr instead of stdout
[-h | --help]           Display this help message${NC}
${TEAL}
------------------- Environment Variables ----------------------${NC}
${BLUE}LOG_TO_STDERR${NC}     - Set this to 'true' to log to stderr.
${BLUE}NO_COLOR${NC}          - Set this to NON-EMPTY to disable all colors.
${BLUE}CLICOLOR_FORCE${NC}    - Set this to NON-ZERO to force colored output.
                    Other color related conditions are ignored.
                  - Colors are disabled if output is not a TTY
EOF
}


function __starship_verify_cheksums()
{
  declare -g STARSHIP_CHECKSUM_RESULT="NA"

  log_info "Fetching starship (checksum)"
  readonly SHARSHIP_REL_ASSET_CHECKSUM="$(curl -sfL "https://github.com/starship/starship/releases/latest/download/${STARSHIP_REL_ASSET_NAME}.sha256")"
  if [[ $SHARSHIP_REL_ASSET_CHECKSUM =~ [A-Fa-f0-9]{64} ]]; then
    log_debug "Checksum is valid hash"
  else
    log_error "Failed to fetch checksum($SHARSHIP_REL_ASSET_CHECKSUM) from GitHub"
    return
  fi

  log_info "Verify SHA256SUM"
  if echo "$SHARSHIP_REL_ASSET_CHECKSUM ${INSTALL_PREFIX}/.cache/shell-tools/starship.tar.gz" | sha256sum --quiet -c -; then
    STARSHIP_CHECKSUM_RESULT="MATCH"
    return
  else
    STARSHIP_CHECKSUM_RESULT="ERROR"
    log_error "SHA256 checksum verification failed!"
  fi
}


function  __starship_detect_variant()
{
  if [[ -z ${STARSHIP_REL_PLATFORM} ]]; then
    readonly variant=$(uname -s)-$(uname -m)
  else
    readonly variant="${STARSHIP_REL_PLATFORM}"
    log_warning "Overriding Installer Variant - ${variant}"
  fi

  case ${variant} in
    # Linux
    Linux-x86_64 )    readonly STARSHIP_REL_ASSET_NAME="starship-x86_64-unknown-linux-musl.tar.gz";;
    Linux-aarch64 )   readonly STARSHIP_REL_ASSET_NAME="starship-aarch64-unknown-linux-musl.tar.gz";;
    # macOS
    Darwin-x86_64 )   readonly STARSHIP_REL_ASSET_NAME="starship-x86_64-apple-darwin.tar.gz";;
    Darwin-aarch64 )  readonly STARSHIP_REL_ASSET_NAME="starship-aarch64-apple-darwin.tar.gz";;
    *)                log_error "Unknown Platform: ${variant}"; exit 1;;
  esac
}


function __starship_download()
{
  log_info "Downloading starship (binary)"
  if curl --progress-bar --location --fail "https://github.com/starship/starship/releases/latest/download/${STARSHIP_REL_ASSET_NAME}" --output "${INSTALL_PREFIX}/.cache/shell-tools/starship.tar.gz"; then
    log_success "OK"
  else
    log_error "Failed fetch binary from GitHub"
    exit 2
  fi
}


function main()
{
  declare -g INSTALL_PREFIX="${HOME}/Junk"
  declare STARSHIP_DOWNLOAD="true"

  if [[ $# -lt 1 ]]; then
    log_error "No arguments specified"
    display_usage
    exit 1
  fi


  while [[ ${1} != "" ]]; do
    case ${1} in
        -i | --install)         INSTALL="true";;
        --test)                 INSTALL_PREFIX="$HOME/Junk";
                                log_warning "Installing to ${INSTALL_PREFIX}";
                                ;;

        # Debugging options
        --stderr)               LOG_TO_STDERR="true";;
        -d | --debug)           LOG_LVL="1";
                                log_info "Enable verbose logging";;
        -h | --help )           display_usage;exit 0;;
        * )                     log_error "Invalid argument(s). See usage below.";
                                display_usage;
                                exit 1;
    esac
    shift
  done


  # Check deps
  if ! has_command curl; then
    log_error "curl is not available!"
    exit 1
  fi

  __starship_detect_variant

  if [[ ! -d "${INSTALL_PREFIX}/.cache/shell-tools" ]]; then
    log_debug "Creating ${INSTALL_PREFIX}/.cache/shell-tools"
    if mkdir -p "${INSTALL_PREFIX}/.cache/shell-tools" ; then
      log_success "OK"
    else
      log_error "Failed to create ${INSTALL_PREFIX}/.cache/shell-tools"
      exit 2
    fi
  else
    log_debug "Cache directory(${INSTALL_PREFIX}/.cache/shell-tools) already exists"
  fi

  # Check if there already exists a starship binary in cache
  if [[ -f  "${INSTALL_PREFIX}/.cache/shell-tools/starship.tar.gz" ]]; then
    log_debug "Verifying existing archive in cache"
    # Verify existing
    __starship_verify_cheksums

    if [[ $STARSHIP_CHECKSUM_RESULT == "MATCH" ]]; then
      log_success "OK"
      STARSHIP_DOWNLOAD="false"
    else
      log_warning "Existing archive did not match the checksum!"
      log_warning "Re-download starship archive"
    fi
  fi

  # Only download if necessary
  if [[ $STARSHIP_DOWNLOAD == "true" ]]; then
    __starship_download
    __starship_verify_cheksums
    if [[ $STARSHIP_CHECKSUM_RESULT == "MATCH" ]]; then
      log_success "OK"
    else
      log_error "SHA256 checksum verification failed!"
      exit 3
    fi
  else
    log_success "No need to download starship again, as the existing archive is verified"
  fi

  log_info "Extract and install starship"

  # Create ~/bin if necessary
  if [[ ! -d "${INSTALL_PREFIX}/bin" ]]; then
    log_debug "Creating ${INSTALL_PREFIX}/bin"
    if mkdir "${INSTALL_PREFIX}/bin" ; then
      log_success "OK"
    else
      log_error "Failed to create ${INSTALL_PREFIX}/bin"
      exit 2
    fi
  else
    log_debug "Bin directory(${INSTALL_PREFIX}/bin) already exists"
  fi

  if tar xzf "${INSTALL_PREFIX}/.cache/shell-tools/starship.tar.gz" -C "${INSTALL_PREFIX}/bin"; then
    log_success "OK"
    log_info "Ensure correct permissions"
    if [[ -x "${INSTALL_PREFIX}/bin/starship" ]]; then
      log_success "OK"
    else
      if chmod +x "${INSTALL_PREFIX}/bin/starship"; then
        log_success "Fixed permissions"
      else
        log_error "Failed to correct permissioons on ${INSTALL_PREFIX}/bin/starship"
      fi
    fi
  else
    log_error "Failed to extract and install starship!"
    exit 3
  fi

  # Fetch latest config from dotfiles repo
  # Create ~/.config if necessary
  if [[ ! -d "${INSTALL_PREFIX}/.config" ]]; then
    log_debug "Creating ${INSTALL_PREFIX}/.config"
    if mkdir "${INSTALL_PREFIX}/.config" ; then
      log_success "OK"
    else
      log_error "Failed to create ${INSTALL_PREFIX}/.config"
      exit 2
    fi
  else
    log_debug "config directory(${INSTALL_PREFIX}/.config) already exists"
  fi

  # Check if there already is a symlink. If so, leave it as is
  # This avoids conflicts with dotfiles installer
  if [[ -L "${INSTALL_PREFIX}/.config/starship.toml" ]]; then
    log_warning "There already exists a starship.toml symlink!"
    log_warning "Script will *NOT* modify it, to avoid breaking tprasadtp/dotfiles installer!"
  else
    log_info "Downloading starship config from tprasadtp/dotfiles"
    if curl --silent \
      --location \
      --fail "https://raw.githubusercontent.com/tprasadtp/dotfiles/master/config/starship/starship.toml" \
      --output "${INSTALL_PREFIX}/.config/starship.toml"; then
      log_success "OK"
    else
      log_error "Failed fetch starship config from dotfiles repository!"
      exit 2
    fi
  fi

  readonly BASHRC_CONTENT_STARSHIP="$(cat << "EOF"
# Snippetizer:Starship:Init:Start
if command -v starship > /dev/null; then
  eval "$(starship init bash)"
fi
alias c='clear'
# Snippetizer:Starship:Init:End
EOF
)"

  # Check if bashrc needs to be created
  if [[ -f "${INSTALL_PREFIX}/.bashrc" ]]; then
    log_debug ".bahsrc is already present"
  else
    log_info "Creating ${INSTALL_PREFIX}/.bashrc"
    if touch "${INSTALL_PREFIX}/.bashrc" ; then
      log_success "OK"
    else
      log_error "Failed to create ${INSTALL_PREFIX}/.bashrc"
      exit 3
    fi
  fi

 # Check if .bashrc has init code
  if grep -q "starship init bash" "${INSTALL_PREFIX}/.bashrc" ; then
    log_notice "It looks like starship initialization code is already in .bashrc"
  else
    log_info "Appending starship init snippet to .bashrc"
    if echo "$BASHRC_CONTENT_STARSHIP" >> "${INSTALL_PREFIX}/.bashrc"; then
      log_success "OK"
    else
      log_error "Failed to append initialization snippet to .bashrc!"
      exit 3
    fi
  fi

}

main "$@"
