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

function display_usage()
{
  #Prints out help menu
  cat <<EOF
Generate and verify SHA512 checksums and GPG signatures.

Usage: ${SCRIPT} [OPTION]...

Arguments:
  None

Options:
  --sign              Generate and sign checksums file
  --verify            Verify existing signatures and checksums
  --verify-skip-gpg   Only verify checksums, and skip GPG verification
  -h, --help          Display help
  -v, --verbose       Increase log verbosity
  --stderr            Log to stderr instead of stdout
  --version           Display script version

Environment:
  LOG_TO_STDERR       Set this to 'true' to log to stderr.
  NO_COLOR            Set this to NON-EMPTY to disable all colors.
  CLICOLOR_FORCE      Set this to NON-ZERO to force colored output.
EOF
}

# Checks if command is available
function has_command()
{
  if command -v "$1" >/dev/null; then
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

  : >SHA512SUMS
  find . -type f \
    -not -path "./.git/**" \
    -not -path "./vendor/**" \
    -not -name "SHA512SUMS" \
    -not -name "SHA512SUMS.asc" \
    "-print0" | xargs "-0" sha512sum \
    >>SHA512SUMS
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
    if gpg --verify "${checksum_sig_file}" "${CURDIR}/SHA512SUMS" 2>/dev/null; then
      log_success "Hooray! digital signature verified"
    else
      log_error "Oh No! Signature checks failed!"
      exit 50
    fi
  elif has_command gpgv >/dev/null; then
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
      --sign) bool_sign_checksum="true" ;;
      --verify) bool_verify_checksum="true" ;;
      --verify-skip-gpg) bool_skip_gpg_verify="true" ;;
      # Debugging options
      --stderr) LOG_TO_STDERR="true" ;;
      -v | --verbose)
        LOG_LVL="0"
        log_info "Enable verbose logging"
        ;;
      --version)
        printf "%s version %s\n" "${SCRIPT}" "${SCRIPT_VERSION:-master}"
        exit 0
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
