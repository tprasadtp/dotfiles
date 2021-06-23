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
