#!/usr/bin/env bash
# Copyright (c) 2021. Prasad Tengse
#
# shellcheck disable=SC2155,SC2034

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



function get_abspath()
{
  # Generate absolute path from relative path
  # ARGUMENTS:
  # $1     : relative filename
  if [ -d "$1" ]; then
    # dir
    (
      cd "$1" || return
      pwd
    )
  elif [ -f "$1" ]; then
    # file
    if [[ $1 = /* ]]; then
      printf "%s" "$1"
    elif [[ $1 == */* ]]; then
      printf "%s" "$(
        cd "${1%/*}" || return
        pwd
      )/${1##*/}"
    else
      printf "%s" "$(pwd)/$1"
    fi
  fi
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

function display_usage()
{
  #Prints out help menu
  cat << EOF
Bash script to run shellcheck usng docker on files specified.

Usage: ${TEAL}${SCRIPT} ${BLUE} [options] ${NC}
${VIOLET}
------------------------- Arguments ----------------------------${NC}
List of Files to run shellcheck on
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

function parse_options()
{
  NON_OPTION_ARGS=()
  while [[ ${1} != "" ]]; do
    case ${1} in
      --stderr) LOG_TO_STDERR="true" ;;
      -v | --verbose)
        LOG_LVL="0"
        log_debug "Enabled verbose logging"
        ;;
      -h | --help)
        display_usage
        exit 0
        ;;
      *) NON_OPTION_ARGS+=("${1}") ;;
    esac
    shift
  done
}

function main()
{
  parse_options "$@"

  if has_command docker; then
    log_debug "Docker cli exists!"
  else
    log_error "Docker not found!"
    log_error "This script uses docker to ensure consistancy in CI/CD systems"
    log_error "Please install docker and try again"
    exit 1
  fi

  # Check if shellcheck version should be changed?
  if [[ -n $SHELLCHECK_VERSION ]]; then
    declare -r SHELLCHECK_VERSION_REGEX="^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\$"
    if [[ ! $SHELLCHECK_VERSION =~ ^v ]]; then
      log_debug "Shellcheck version specified does not start with prefix v, append it"
      SHELLCHECK_VERSION="v${SHELLCHECK_VERSION}"
    fi

    if [[ $SHELLCHECK_VERSION =~ $SHELLCHECK_VERSION_REGEX ]]; then
      log_debug "Shellcheck version is valid"
    else
      log_error "Invalid shellcheck version"
      log_error "Version specified must match regex: ${SHELLCHECK_VERSION_REGEX}"
      exit 1
    fi
  else
    SHELLCHECK_VERSION="v0.7.2"
  fi

  log_notice "Using shellcheck version tag: ${SHELLCHECK_VERSION}"

  # check if docker image is available
  if docker inspect "koalaman/shellcheck:${SHELLCHECK_VERSION}" > /dev/null 2>&1; then
    log_debug "Using existing image - koalaman/shellcheck:${SHELLCHECK_VERSION}"
  else
    log_info "Pull docker image: koalaman/shellcheck:${SHELLCHECK_VERSION} "
    if docker pull koalaman/shellcheck:${SHELLCHECK_VERSION}; then
      log_success "Pull OK"
    else
      log_error "Shellcheck image specified is not present on local system"
      log_error "or on dockerhub. No image - koalaman/shellcheck:${SHELLCHECK_VERSION}"
      exit 1
    fi
  fi

  declare -ga SHELLCHECK_FILES
  declare -ga SHELLCHECK_ERRORS
  declare abs_file_path

  # Loop over non option arguments and check if the files are
  # present and are readable
  for file in "${NON_OPTION_ARGS[@]}"; do
    abs_file_path=""
    # absolute path takes priority
    if [[ -r ${file} ]]; then
      log_debug "Readable file: ${file}"
      abs_file_path="$(get_abspath "${file}")"
    # search in REPO_ROOT if REPO_ROOT is defined
    elif [[ -r ${REPO_ROOT}/${file} ]] && [[ -n ${REPO_ROOT} ]]; then
      log_debug "Readable file: ${REPO_ROOT}/${file} (REPO_ROOT)"
      abs_file_path="$(get_abspath "${REPO_ROOT}/${file}")"
    else
      log_error "File not found : ${file}"
    fi

    if [[ -n ${abs_file_path} ]]; then
      log_debug "Adding ${abs_file_path} to file list"
      SHELLCHECK_FILES+=("${abs_file_path}")
    fi
  done

  if [[ ${#SHELLCHECK_FILES[@]} -eq 0 ]]; then
    log_error "No files to shellcheck!"
    exit 1
  else
    local res
    # Use shellcheck docker image for consistancy
    for file in "${SHELLCHECK_FILES[@]}"; do
      file_basename="$(basename "${file}")"
      log_info "$file"
      docker run \
        --rm \
        --workdir=/app/ \
        --network=none \
        -v "${file}:/app/${file_basename}:ro" \
        koalaman/shellcheck:"${SHELLCHECK_VERSION}" \
        --color=always \
        "/app/${file_basename}"
      res="$?"
      if [[ $res -eq 0 ]]; then
        log_success "OK"
      else
        SHELLCHECK_ERRORS+=("${file}")
        log_error "FAILED"
      fi
    done
  fi

  if [ ${#SHELLCHECK_ERRORS[@]} -eq 0 ]; then
    log_notice "Hooray! All files passed shellcheck."
  else
    log_error "${#SHELLCHECK_ERRORS[*]} file(s) failed shellcheck: ${SHELLCHECK_ERRORS[*]}"
    exit 1
  fi
}

main "$@"

# diana:{diana_urn_flavor}:{remote}:{source}:{version}:{remote_path}:{type}
# diana:2:github:tprasadtp/templates::scripts/shellcheck.sh:static
