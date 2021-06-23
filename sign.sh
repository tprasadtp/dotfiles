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

# Logging colors
# - If set they are preserved,
# - Otherwise initialized wit ha readonly variable.
[[ -z ${DARK_GRAY+unset} ]] && readonly DARK_GRAY=$'\e[38;5;246m'
[[ -z ${GRAY+unset} ]] && readonly GRAY=$'\e[38;5;250m'
[[ -z ${GREEN+unset} ]] && readonly GREEN=$'\e[38;5;83m'
[[ -z ${BLUE+unset} ]] && readonly BLUE=$'\e[38;5;81m'
[[ -z ${YELLOW+unset} ]] && readonly YELLOW=$'\e[38;5;214m'
[[ -z ${RED+unset} ]] && readonly RED=$'\e[38;5;197m'

# Default log level and formats
# We set these only if theexisting values are empty
[[ -z $LOG_FMT ]] && declare -g LOG_FMT="pretty"
[[ -z $LOG_LVL ]] && declare -g LOG_LVL="20"

# Logger core
function __logger_core()
{
  # If no arguments were specified return now
  [[ $# -eq 0 ]] && return

  # Determine level based on caller function,
  # and return if not called form known functions.
  # This effectively makes this function private-ish

  if [[ -n $BASH_VERSION ]]; then
    local -r lvl_caller="${FUNCNAME[1]}"
  else
    # Ughh Apple! zsh!
    # Use offset:length as array indexing may start at 1 or 0
    # shellcheck disable=SC2124,SC2154
    local -r lvl_caller="${funcstack[@]:1:1}"
  fi

  case $lvl_caller in
    log_step_variable | log_variable) local -r level=0 ;;
    log_step_debug | log_debug) local -r level=10 ;;
    log_step_info | log_info) local -r level=20 ;;
    log_step_success | log_success) local -r level=20 ;;
    log_step_warning | log_warning) local -r level=30 ;;
    log_step_notice | log_notice) local -r level=35 ;;
    log_step_error | log_error) local -r level=40 ;;
    *) return ;;
  esac

  # Immediately return if log level is not enabled
  [[ ${LOG_LVL} -gt $level ]] && return

  # Detect whether to coloring is disabled based on env variables,
  # and if output Terminal is intractive. This supports both
  # - https://bixense.com/clicolors/ &
  # - https://no-color.org/ standards.

  # Forces colored logs
  # - if CLICOLOR_FORCE is set and non empty and not zero
  #
  if [[ -n ${CLICOLOR_FORCE} ]] && [[ ${CLICOLOR_FORCE} != "0" ]]; then
    local lvl_colorized="true"
    local lvl_color_reset=$'\e[0m'

  # Disable colors if one of the conditions are true
  # - CLICOLOR == 0
  # - NO_COLOR is set to non empty value
  # - TERM is set to dumb
  elif [[ -n $NO_COLOR ]] || [[ $CLICOLOR == "0" ]] || [[ $TERM == "dumb" ]]; then
    local lvl_colorized="false"
    local lvl_color=""
    local lvl_color_reset=""

  # Enable colors if not already disabled or forced and terminal is interactive
  elif [[ -t 1 ]]; then
    local lvl_colorized="true"
    local lvl_color_reset=$'\e[0m'

  # Default=disable colors
  else
    local lvl_colorized="false"
    local lvl_color=""
    local lvl_color_reset=""
  fi

  # Log Format
  if [[ $LOG_FMT == "full" || $LOG_FMT == "long" || $lvl_colorized == "false" ]]; then
    local -r lvl_prefix="$(date --rfc-3339=s)"
    local -r lvl_fmt="long"
  elif [[ $lvl_caller == *"step"* ]]; then
    local -r lvl_string="  -"
    local -r lvl_fmt="pretty"
  else
    local -r lvl_string="•"
    local -r lvl_fmt="pretty"
  fi

  # Define level, color and timestamp
  # By default we do not show log level and timestamp.
  # However, if LOG_FMT is set to "full" or "long" or if colors are disabled,
  # we will enable long format with timestamps
  case $lvl_caller in
    log_step_variable | log_variable)
      [[ $lvl_fmt  == "long"  ]] && local -r lvl_string="$lvl_prefix [TRACE ]"
      [[ $lvl_colorized == "true" ]] && local lvl_color="${DARK_GRAY}"
      ;;
    log_step_debug | log_debug)
      [[ $lvl_fmt  == "long"  ]] && local -r lvl_string="$lvl_prefix [DEBUG ]"
      [[ $lvl_colorized == "true" ]] && local lvl_color="${GRAY}"
      ;;
    log_step_info | log_info)
      [[ $lvl_fmt  == "long"  ]] && local -r lvl_string="$lvl_prefix [INFO  ]"
      ;;
    log_step_success | log_success)
      [[ $lvl_fmt  == "long"  ]] && local -r lvl_string="$lvl_prefix [OK    ]"
      [[ $lvl_colorized == "true" ]] && local lvl_color="${GREEN}"
      ;;
    log_step_warning | log_warning)
      [[ $lvl_fmt  == "long"  ]] && local -r lvl_string="$lvl_prefix [WARN  ]"
      [[ $lvl_colorized == "true" ]] && local lvl_color="${YELLOW}"
      ;;
    log_step_notice | log_notice)
      [[ $lvl_fmt  == "long"  ]] && local -r lvl_string="$lvl_prefix [NOTICE]"
      [[ $lvl_colorized == "true" ]] && local lvl_color="${BLUE}"
      ;;
    log_step_error | log_error)
      [[ $lvl_fmt  == "long"  ]] && local -r lvl_string="$lvl_prefix [ERROR ]"
      [[ $lvl_colorized == "true" ]] && local lvl_color="${RED}"
      ;;
    *)
      [[ $lvl_fmt  == "long"  ]] && local -r lvl_string="$lvl_prefix [UNKOWN] $lvl_caller"
      ;;
  esac

  # Log Event
  local msg="$*"
  if [[ ${LOG_TO_STDERR} == "true" ]]; then
    printf "%s%s %s %s\n" "$lvl_color" "${lvl_string}" "$msg" "${lvl_color_reset}" 1>&2
  else
    printf "%s%s %s %s\n" "$lvl_color" "${lvl_string}" "$msg" "${lvl_color_reset}"
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
  local -r var="$1"
  if [[ -n $BASH_VERSION ]]; then
    local -r msg="$var=${!var}"
  else
    local -r msg="$var=${(P)var}"
  fi
  __logger_core "$msg"
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
  local -r var="$1"
  if [[ -n $BASH_VERSION ]]; then
    local -r msg="$var=${!var}"
  else
    local -r msg="$var=${(P)var}"
  fi
  __logger_core "$msg"
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
