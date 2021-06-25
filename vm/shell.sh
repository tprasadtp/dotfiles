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

#>> diana::snippet:bash-logger:begin <<#
# shellcheck shell=sh
# shellcheck disable=SC3043

# SHELL LOGGING LIBRARY
# See https://github.com/tprasadtp/dotfiles/libs/logger/README.md
# If included in other files, contents between snippet markers is
# automatically updated and all changes between markers wil be ignored.

# Logger core
__logger_core_event_handler()
{
  [ "$#" -lt 2 ] && return

  # Caller is same as level name
  local lvl_caller="${1:-info}"

  case $lvl_caller in
    log_trace | trace)
      lvl_caller="trace"
      level="0"
      ;;
    log_debug | debug)
      lvl_caller="debug"
      level="10"
      ;;
    log_info | info)
      lvl_caller="info"
      level="20"
      ;;
    log_success | success | ok)
      lvl_caller="success"
      level="20"
      ;;
    log_warning | warning | warn)
      lvl_caller="warning"
      level="30"
      ;;
    log_notice | notice)
      lvl_caller="notice"
      level="35"
      ;;
    log_error | error)
      lvl_caller="error"
      level="40"
      ;;
    *)
      level="40"
      ;;
  esac

  # Immediately return if log level is not enabled
  # If LOG_LVL is not set, defaults to 20 - info level
  [ "${LOG_LVL:-20}" -gt "$level" ] && return

  shift
  local lvl_msg="$*"

  # Detect whether to coloring is disabled based on env variables,
  # and if output Terminal is intractive. This supports both
  # - https://bixense.com/clicolors/ &
  # - https://no-color.org/ standards.

  # Forces colored logs
  # - if CLICOLOR_FORCE is set and non empty and not zero
  #
  if [ -n "${CLICOLOR_FORCE}" ] && [ "${CLICOLOR_FORCE}" != "0" ]; then
    local lvl_colorized="true"
    # shellcheck disable=SC2155
    local lvl_color_reset="$(printf '\e[0m')"

  # Disable colors if one of the conditions are true
  # - CLICOLOR = 0
  # - NO_COLOR is set to non empty value
  # - TERM is set to dumb
  elif [ -n "$NO_COLOR" ] || [ "$CLICOLOR" = "0" ] || [ "$TERM" = "dumb" ]; then
    local lvl_colorized="false"
    local lvl_color=""
    local lvl_color_reset=""

  # Enable colors if not already disabled or forced and terminal is interactive
  elif [ -t 1 ]; then
    local lvl_colorized="true"
    # shellcheck disable=SC2155
    local lvl_color_reset="$(printf '\e[0m')"

  # Default=disable colors
  else
    local lvl_colorized="false"
    local lvl_color=""
    local lvl_color_reset=""
  fi

  # Log and Date formatter
  if [ "${LOG_FMT:-pretty}" = "pretty" ] && [ "$lvl_colorized" = "true" ]; then
    local lvl_string="•"
  elif [ "${LOG_FMT}" = "full" ] || [ "${LOG_FMT}" = "long" ]; then
    local lvl_prefix="name+ts"
    # shellcheck disable=SC2155
    local lvl_ts="$(date --rfc-3339=s)"
  else
    local lvl_prefix="name"
  fi

  # Define level, color and timestamp
  # By default we do not show log level and timestamp.
  # However, if LOG_FMT is set to "full" or "long" or if colors are disabled,
  # we will enable long format with timestamps
  case "$lvl_caller" in
    trace)
      [ "$lvl_prefix" = "name" ] && local lvl_string="[TRACE ]"
      [ "$lvl_prefix" = "name+ts" ] && local lvl_string="$lvl_ts [TRACE ]"
      # shellcheck disable=SC2155
      [ "$lvl_colorized" = "true" ] && local lvl_color="$(printf '\e[38;5;246m')"
      ;;
    debug)
      [ "$lvl_prefix" = "name" ] && local lvl_string="[DEBUG ]"
      [ "$lvl_prefix" = "name+ts" ] && local lvl_string="$lvl_ts [DEBUG ]"
      # shellcheck disable=SC2155
      [ "$lvl_colorized" = "true" ] && local lvl_color="$(printf '\e[38;5;250m')"
      ;;
    info)
      [ "$lvl_prefix" = "name" ] && local lvl_string="[INFO  ]"
      [ "$lvl_prefix" = "name+ts" ] && local lvl_string="$lvl_ts [INFO  ]"
      # Avoid printing color reset sequence as this level is not colored
      [ "$lvl_colorized" = "true" ] && lvl_color_reset=""
      ;;
    success)
      [ "$lvl_prefix" = "name" ] && local lvl_string="[OK    ]"
      [ "$lvl_prefix" = "name+ts" ] && local lvl_string="$lvl_ts [OK    ]"
      # shellcheck disable=SC2155
      [ "$lvl_colorized" = "true" ] && local lvl_color="$(printf '\e[38;5;83m')"
      ;;
    warning)
      [ "$lvl_prefix" = "name" ] && local lvl_string="[WARN  ]"
      [ "$lvl_prefix" = "name+ts" ] && local lvl_string="$lvl_ts [WARN  ]"
      # shellcheck disable=SC2155
      [ "$lvl_colorized" = "true" ] && local lvl_color="$(printf '\e[38;5;214m')"
      ;;
    notice)
      [ "$lvl_prefix" = "name" ] && local lvl_string="[NOTICE]"
      [ "$lvl_prefix" = "name+ts" ] && local lvl_string="$lvl_ts [NOTICE]"
      # shellcheck disable=SC2155
      [ "$lvl_colorized" = "true" ] && local lvl_color="$(printf '\e[38;5;81m')"
      ;;
    error)
      [ "$lvl_prefix" = "name" ] && local lvl_string="[ERROR ]"
      [ "$lvl_prefix" = "name+ts" ] && local lvl_string="$lvl_ts [ERROR ]"
      # shellcheck disable=SC2155
      [ "$lvl_colorized" = "true" ] && local lvl_color="$(printf '\e[38;5;197m')"
      ;;
    *)
      [ "$lvl_prefix" = "name" ] && local lvl_string="[UNKOWN]"
      [ "$lvl_prefix" = "name+ts" ] && local lvl_string="$lvl_ts [UNKNOWN]"
      # Avoid printing color reset sequence as this level is not colored
      [ "$lvl_colorized" = "true" ] && lvl_color_reset=""
      ;;
  esac

  if [ "${LOG_TO_STDERR:-false}" = "true" ]; then
    printf "%s%s %s %s\n" "$lvl_color" "${lvl_string}" "$lvl_msg" "${lvl_color_reset}" 1>&2
  else
    printf "%s%s %s %s\n" "$lvl_color" "${lvl_string}" "$lvl_msg" "${lvl_color_reset}"
  fi
}

# Leveled Loggers
log_trace()
{
  __logger_core_event_handler "trace" "$@"
}

log_debug()
{
  __logger_core_event_handler "debug" "$@"
}

log_info()
{
  __logger_core_event_handler "info" "$@"
}

log_success()
{
  __logger_core_event_handler "ok" "$@"
}

log_warning()
{
  __logger_core_event_handler "warn" "$@"
}

log_warn()
{
  __logger_core_event_handler "warn" "$@"
}

log_notice()
{
  __logger_core_event_handler "notice" "$@"
}

log_error()
{
  __logger_core_event_handler "error" "$@"
}
#>> diana::snippet:bash-logger:end <<#


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
