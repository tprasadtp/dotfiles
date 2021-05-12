#!/usr/bin/env bash
#  Copyright (c) 2018-2021. Prasad Tengse
#
# shellcheck disable=SC2034,SC2155

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


function display_usage()
{
#Prints out help menu
cat <<EOF
Bash script to to checksum and sign files.

Note:
Fonts and git directory are excluded.

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

# Logging Handlers

# Define colors for logging
function define_colors()
{
  declare -gr YELLOW=$'\e[38;5;214m'
  declare -gr GREEN=$'\e[38;5;83m'
  declare -gr RED=$'\e[38;5;197m'
  declare -gr NC=$'\e[0m'

  # Enhanced colors
  declare -gr PINK=$'\e[38;5;212m'
  declare -gr BLUE=$'\e[38;5;81m'
  declare -gr ORANGE=$'\e[38;5;208m'
  declare -gr TEAL=$'\e[38;5;192m'
  declare -gr VIOLET=$'\e[38;5;219m'
  declare -gr GRAY=$'\e[38;5;250m'
  declare -gr DARK_GRAY=$'\e[38;5;246m'

  # Flag
  declare -gr COLORIZED=1
}

function undefine_colors()
{
  # Disable all colors
  declare -gr YELLOW=""
  declare -gr GREEN=""
  declare -gr RED=""
  declare -gr NC=""

  # Enhanced colors
  declare -gr PINK=""
  declare -gr BLUE=""
  declare -gr ORANGE=""
  declare -gr TEAL=""
  declare -gr VIOLET=""
  declare -gr GRAY=""
  declare -gr DARK_GRAY=""

  # Flag
  declare -gr COLORIZED=1
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


function generate_checksums()
{
  log_info "Checksum will be saved as, SHA512SUMS"
  log_info "Any previous file by that name will be emptied"

  : > SHA512SUMS
  find . -type f \
			-not -path "./.git/**" \
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

function verify_checksums() {
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
  # Lets declare variables
  local checksum_sig_file
  # Checks if file is present
  if [ -f "${CURDIR}/SHA512SUMS.asc" ]; then
    checksum_sig_file="${CURDIR}/SHA512SUMS.asc"
  else
    log_error "Error! signature file not found!"
    exit 1;
  fi

  # Check for signature files
  log_info "Verifying digital signature of checksums"
  log_info "Signature File : ${checksum_sig_file}"
  log_info "Data File      : ${CURDIR}/SHA512SUMS"
  # Checks for commands
  if has_command gpg ; then
    if gpg --verify "${checksum_sig_file}" "${CURDIR}/SHA512SUMS" 2>/dev/null; then
      log_success "Hooray! digintal signature verified"
    else
      log_error "Oh No! Signature checks failed!"
      exit 50;
    fi
  elif has_command gpgv > /dev/null; then
    if gpgv --keyring "$HOME/.gnupg/pubring.kbx" "${checksum_sig_file}" "${CURDIR}/SHA512SUMS"; then
      log_success "Signature verified"
    else
      log_error "Signature checks failed!!"
      exit 50;
    fi
  else
    log_error "Cannot perform verification. gpgv or gpg is not installed."
    log_error "This action requires gnugpg/gnupg2 or gpgv package."
    exit 1;
  fi
}

function main()
{
  # No args just run the setup function
  if [[ $# -eq 0 ]]; then
    log_error "No Action specified!"
    display_usage;
    exit 1
  fi

  while [[ ${1} != "" ]]; do
    case ${1} in
        -s | --sign)            bool_sign_checksum="true";;
        -v | --verify)          bool_verify_checksum="true";;
        -G | --skip-gpg-verify) bool_skip_gpg_verify="true";;
        # Debugging options
        --stderr)               LOG_TO_STDERR="true";;
        -d | --debug)           LOG_LVL="1";
                                log_info "Enable verbose logging";;
        -h | --help )           display_usage;exit 0;;
        * )                     log_error "Invalid argument(s). See usage below.";
                                display_usage;
                                exit 1;    esac
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
