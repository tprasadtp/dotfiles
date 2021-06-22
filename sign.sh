#!/usr/bin/env bash
#  Copyright (c) 2018-2021. Prasad Tengse
#
# shellcheck disable=SC2034,SC2155

set -o pipefail

# Script Constants
readonly CURDIR="$(cd -P -- "$(dirname -- "")" && pwd -P)"
readonly SCRIPT="$(basename "$0")"

# Handle Signals
# trap ctrl-c and SIGTERM
trap ctrl_c_signal_handler INT
trap term_signal_handler SIGTERM

function ctrl_c_signal_handler()
                                 {
  log_error "User Interrupt! CTRL-C"
  exit 4
}
function term_signal_handler()
                               {
  log_error "Signal Interrupt! SIGTERM"
  exit 4
}


#>> diana::snippet:bash-logger:begin <<#
# shellcheck shell=bash

# BASH LOGGING LIBRARY
# See https://github.com/tprasadtp/dotfiles/logger/README.md
# If included in other files, contents between snippet markers is
# automatically updated and all changes wil be ignored.

# Define standard logging colors
[[ ! -v ${DGRAY} ]] && declare -gr DGRAY=$'\e[38;5;246m'
[[ ! -v ${GRAY} ]] && declare -gr GRAY=$'\e[38;5;250m'
[[ ! -v ${GREEN} ]] && declare -gr GREEN=$'\e[38;5;83m'
[[ ! -v ${BLUE} ]] && declare -gr BLUE=$'\e[38;5;81m'
[[ ! -v ${YELLOW} ]] && declare -gr YELLOW=$'\e[38;5;214m'
[[ ! -v ${RED} ]] && declare -gr RED=$'\e[38;5;197m'

# Default log level and formats
[[ -z $LOG_FMT ]] && declare -g LOG_FMT="pretty"
[[ -z $LOG_LVL ]] && declare -g LOG_LVL="20"

# Logger core
function __logger_core()
{
  # If no arguments were specified return now
  [[ $# -eq 0 ]] && return

  # Determine level based on caller function,
  # and return if not called form known functions.
  # This effectively makes this function private-ish err somewhat.
  case ${FUNCNAME[1]} in
    log_step_variable | log_variable) local level=0 ;;
    log_step_debug | log_debug) local level=10 ;;
    log_step_info | log_info) local level=20 ;;
    log_step_success | log_success) local level=20 ;;
    log_step_warning | log_warning) local level=30 ;;
    log_step_notice | log_notice) local level=35 ;;
    log_step_error | log_error) local level=40 ;;
    *) return ;;
  esac

  # Immediately return if log level is not enabled
  [[ ${LOG_LVL} -gt "$level" ]] && return

  # Level string & color
  local lvl_string="•"
  local lvl_color=""
  local lvl_color_reset=""

  # Detect whether to coloring is disabled based on env variables,
  # and if output Terminal is intractive. This supports both
  # - https://bixense.com/clicolors/ &
  # - https://no-color.org/ standards.

  # Forces colored logs
  # - if CLICOLOR_FORCE is set and non empty
  #
  if [[ -n ${CLICOLOR_FORCE} ]] && [[ ${CLICOLOR_FORCE} != "0" ]]; then
    local lvl_colorized="true"

  # Disable colors if
  # - CLICOLOR == 0
  # - NO_COLOR is set to non empty value
  #
  elif [[ -n $NO_COLOR ]] || [[ $CLICOLOR == "0" ]]; then
    local lvl_colorized="false"

  # Enable colors
  # - If TERM is NOT set to dumb and
  # - Terminal is interactive
  elif [[ -t 1 ]] && [[ $TERM != "dumb" ]]; then
    local lvl_colorized="true"
    local lvl_color_reset=$'\e[0m'
  # Proably Terminal is non-interactive, disable colors
  else
    local lvl_colorized="false"
  fi

  # Indent
  # For pretty logging we indent for log_step* funcs
  # as it looks better and improves redability.
  # Instead of specifying this during calltime, we check our funcstack
  # to check if __logger_core was called from log_step* function.
  # We will not do this if one of the conditions is true,
  #   log-fmt was full
  #   colors were disabled
  if [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]]; then
    local lvl_indent=""
  elif [[ ${FUNCNAME[1]} =~ ^log_step* ]]; then
    local lvl_indent="  "
    lvl_string="-"
  else
    local lvl_indent=""
  fi

  # Define level, color and timestamp
  # By default we do not show log level and timestamp.
  # However, if log-fmt is set to "full" or if colors are disabled,
  # we will enable long format with timestamps
  case ${FUNCNAME[1]} in
    log_step_variable | log_variable)
      [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [TRACE ]"
      [[ $lvl_colorized == "true" ]] && local lvl_color="${DGRAY}"
      ;;
    log_step_debug | log_debug)
      [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [DEBUG ]"
      [[ $lvl_colorized == "true" ]] && local lvl_color="${GRAY}"
      ;;
    log_step_info | log_info)
      [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [INFO  ]"
      ;;
    log_step_success | log_success)
      [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [OK    ]"
      [[ $lvl_colorized == "true" ]] && local lvl_color="${GREEN}"
      ;;
    log_step_warning | log_warning)
      [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [WARN  ]"
      [[ $lvl_colorized == "true" ]] && local lvl_color="${YELLOW}"
      ;;
    log_step_notice | log_notice)
      [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [NOTICE]"
      [[ $lvl_colorized == "true" ]] && local lvl_color="${BLUE}"
      ;;
    log_step_error | log_error)
      [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [ERROR ]"
      [[ $lvl_colorized == "true" ]] && local lvl_color="${RED}"
      ;;
    *)
      [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [UNKOWN]"
      ;;
  esac

  # Log Event
  local msg="$*"
  if [[ ${LOG_TO_STDERR} == "true" ]]; then
    printf "%s%s%s %s %s\n" "${lvl_color}" "${lvl_indent}" "${lvl_string}" "$msg" "${lvl_color_reset}" 1>&2
  else
    printf "%s%s%s %s %s\n" "${lvl_color}" "${lvl_indent}" "${lvl_string}" "$msg" "${lvl_color_reset}"
  fi
}

# Logger public functions
function log_debug()
{
  __logger_core "$@"
}

function log_info()
{
  __logger_core "$@"
}

function log_success()
{
  __logger_core "$@"
}

function log_notice()
{
  __logger_core "$@"
}

function log_warning()
{
  __logger_core "$@"
}

function log_error()
{
  __logger_core "$@"
}

function log_variable()
{
  local var
  var="$1"
  __logger_core "$(printf "%s=%s" "${var}" "${!var}")"
}

function log_step_debug()
{
  __logger_core "$@"
}

function log_step_info()
{
  __logger_core "$@"
}

function log_step_success()
{
  __logger_core "$@"
}

function log_step_notice()
{
  __logger_core "$@"
}

function log_step_warning()
{
  __logger_core "$@"
}

function log_step_error()
{
  __logger_core "$@"
}

function log_step_variable()
{
  local var
  var="$1"
  __logger_core "$(printf "%s=%s" "${var}" "${!var}")"
}
#>> diana::snippet:bash-logger:end <<#


function display_usage()
{
  #Prints out help menu
  cat << EOF
Bash script to to checksum and sign files.

Usage: ${TEAL}${SCRIPT} ${BLUE} [options] ${NC}
${VIOLET}
------------------------- Options ------------------------------${NC}
[-s --sign]             Generate and sign SHA512SUMS file
[-v --verify]           Verify SHA512 and GPG signatures
[-G --skip-gpg-verify]  Skip verifying GPG signature
${ORANGE}
---------------- Options with Required Argments-----------------${NC}
None
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


# Checks if command is available
function has_command()
{
  if command -v "$1" > /dev/null; then
    return 0
  else
    return 1
  fi
  return 1
}

function generate_checksums()
{
  log_info "Checksum will be saved as, SHA512SUMS"
  log_info "Any previous file by that name will be emptied"

  : > SHA512SUMS
  find . -type f \
    -not -path "./.git/**" \
    -not -path "./vendor/**" \
      -not -name "SHA512SUMS" \
      -not -name "SHA512SUMS.asc" \
      "-print0" | xargs "-0" sha512sum \
    >> SHA512SUMS
  log_success "Generated SHA512 checksums"
}

function sign_checksum()
{
  if [[ -f "${CURDIR}/SHA512SUMS" ]]; then
    log_info "Signing ${CURDIR}/SHA512SUMS"

    if gpg --armor --detach-sign \
      --output "${CURDIR}/SHA512SUMS.asc" \
      --yes --no-tty \
      "${CURDIR}/SHA512SUMS"; then
      log_success "Signed ${CURDIR}/SHA512SUMS"
    else
      log_error "Failed to sign ${CURDIR}/SHA512SUMS"
      exit 2
    fi
  else
    log_error "SHA512SUMS file not found!: ${CURDIR}/SHA512SUMS "
    exit 2
  fi
}

function verify_checksums()
                            {
  log_info "Verifying SHA512SUMS"
  if [[ -f ${CURDIR}/SHA512SUMS ]]; then
    printf "%s" "${YELLOW}"
    if sha512sum -c "${CURDIR}/SHA512SUMS" --strict --quiet; then
      printf "%s" "${NC}"
      log_success "Hooray! SHA512 checksums verified"
    else
      log_error "Failed! Some files failed checksum verification!"
      log_error "Manually run 'sha512sum -c ${CURDIR}/SHA512SUMS' to check for errors."
      exit 2
    fi
  else
    log_error "File ${CURDIR}/SHA512SUMS not found!"
    exit 1
  fi
}

function verify_gpg_signature()
{
  # Verifies the file with its detached GPG signature.
  # Assumes that you already have public key in your keyring.
  # Assumes signature file is present at same localtion,
  # with same name but with .sig or .gpg or .asc extension.
  local checksum_sig_file
  # Checks if file is present
  if [ -f "${CURDIR}/SHA512SUMS.asc" ]; then
    checksum_sig_file="${CURDIR}/SHA512SUMS.asc"
  else
    log_error "Error! signature file not found!"
    exit 1
  fi

  # Check for signature files
  log_info "Verifying digital signature of checksums"
  log_info "Signature File : ${checksum_sig_file}"
  log_info "Data File      : ${CURDIR}/SHA512SUMS"
  # Checks for commands
  if has_command gpg; then
    if gpg --verify "${checksum_sig_file}" "${CURDIR}/SHA512SUMS" 2> /dev/null; then
      log_success "Hooray! digital signature verified"
    else
      log_error "Oh No! Signature checks failed!"
      exit 50
    fi
  elif has_command gpgv > /dev/null; then
    if gpgv --keyring "$HOME/.gnupg/pubring.kbx" "${checksum_sig_file}" "${CURDIR}/SHA512SUMS"; then
      log_success "Signature verified"
    else
      log_error "Signature checks failed!!"
      exit 50
    fi
  else
    log_error "Cannot perform verification. gpgv or gpg is not installed."
    log_error "This action requires gnugpg/gnupg2 or gpgv package."
    exit 1
  fi
}

function main()
{
  # No args just run the setup function
  if [[ $# -eq 0 ]]; then
    log_error "No Action specified!"
    display_usage
    exit 1
  fi

  while [[ ${1} != "" ]]; do
    case ${1} in
        --sign)                 bool_sign_checksum="true" ;;
        --verify)               bool_verify_checksum="true" ;;
        -G | --skip-gpg-verify) bool_skip_gpg_verify="true" ;;
        # Debugging options
        --stderr)               LOG_TO_STDERR="true" ;;
        -v | --verbose)
                                LOG_LVL="0"
                                log_info "Enable verbose logging"
                                                                 ;;
        -h | --help)
                                display_usage
                                              exit 0
                                                    ;;
        *)
                                log_error "Invalid argument(s). See usage below."
                                display_usage
                                exit 1
        ;;
    esac
    shift
  done

  # Actions

  if [[ $bool_sign_checksum == "true" ]]; then
    generate_checksums
    sign_checksum
  fi

  if [[ $bool_verify_checksum == "true" ]]; then
    verify_checksums
    if [[ $bool_skip_gpg_verify == "true" ]]; then
      log_warning "Skipping signature verification of checksums"
    else
      verify_gpg_signature
    fi
  fi

}

main "$@"
