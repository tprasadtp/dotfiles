#!/bin/bash
# shellcheck disable=SC2034

### BEGIN LOGGING SNIPPET ###

# Define standard logging colors
[[ ! -v ${DGRAY}  ]]  && declare -gr DGRAY=$'\e[38;5;246m'
[[ ! -v ${GRAY}  ]]   && declare -gr GRAY=$'\e[38;5;250m'
[[ ! -v ${GREEN}  ]]  && declare -gr GREEN=$'\e[38;5;83m'
[[ ! -v ${BLUE}  ]]   && declare -gr BLUE=$'\e[38;5;81m'
[[ ! -v ${YELLOW} ]] && declare -gr YELLOW=$'\e[38;5;214m'
[[ ! -v ${RED}  ]]    && declare -gr RED=$'\e[38;5;197m'
[[ ! -v ${NC}  ]]     && declare -gr NC=$'\e[0m'

# Default log level and format
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
    log_step_variable | log_variable)   local level=0 ;;
    log_step_debug | log_debug)         local level=10 ;;
    log_step_info |  log_info)          local level=20 ;;
    log_step_success |  log_success)    local level=25 ;;
    log_step_warning |  log_warning)    local level=30 ;;
    log_step_notice |  log_notice)      local level=35 ;;
    log_step_error |  log_error)        local level=40 ;;
    *)                                  return ;;
  esac

  # Immediately return if log level is not enabled
  [[ ${LOG_LVL} -gt "$level" ]] && return

  # Disable colord output by default
  local lvl_colorized="false"

  # Level string & color
  local lvl_string="•"
  local lvl_color=""
  local lvl_color_reset=""

  # Forces colors
  if [[ -n ${CLICOLOR_FORCE} ]] && [[ ${CLICOLOR_FORCE} != "0" ]]; then
    lvl_colorized="forced"
  # Enables colors if terminal is interactive and NOCOLOR is not empty and TERM is not dumb
  elif [[ -t 1 ]] && [[ -z ${NO_COLOR} ]] && [[ ${TERM} != "dumb" ]]; then
    lvl_colorized="true"
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
  case ${level} in
    0 | 00)
          [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [TRACE ]"
          [[ $lvl_colorized =~ (true|forced) ]] && local lvl_color="${DGRAY}"
          [[ $lvl_colorized =~ (true|forced) ]] && local lvl_color_reset="${NC}"
          ;;
    10)
          [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [DEBUG ]"
          [[ $lvl_colorized =~ (true|forced) ]] && local lvl_color="${GRAY}"
          [[ $lvl_colorized =~ (true|forced) ]] && local lvl_color_reset="${NC}"
          ;;
    20)
          [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [INFO  ]"
          ;;
    25)
          [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [OK    ]"
          [[ $lvl_colorized =~ (true|forced) ]] && local lvl_color="${GREEN}"
          [[ $lvl_colorized =~ (true|forced) ]] && local lvl_color_reset="${NC}"
          ;;
    30)
          [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [WARN  ]"
          [[ $lvl_colorized =~ (true|forced) ]] && local lvl_color="${YELLOW}"
          [[ $lvl_colorized =~ (true|forced) ]] && local lvl_color_reset="${NC}"
          ;;
    35)
          [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [NOTICE]"
          [[ $lvl_colorized =~ (true|forced) ]] && local lvl_color="${BLUE}"
          [[ $lvl_colorized =~ (true|forced) ]] && local lvl_color_reset="${NC}"
          ;;
    40)
          [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [ERROR ]"
          [[ $lvl_colorized =~ (true|forced) ]] && local lvl_color="${RED}"
          [[ $lvl_colorized =~ (true|forced) ]] && local lvl_color_reset="${NC}"
          ;;
    *)
          [[ $LOG_FMT == "full" || $lvl_colorized == "false" ]] && lvl_string="$(date --rfc-3339=s) [UNKOWN]"
          ;;
  esac

  # Logging
  if [[ ${LOG_TO_STDERR} == "true" ]]; then
    printf "%s%s%s %s %s\n" "${lvl_color}" "${lvl_indent}" "${lvl_string}" "$@" "${lvl_color_reset}" 1>&2
  else
    printf "%s%s%s %s %s\n" "${lvl_color}" "${lvl_indent}" "${lvl_string}" "$@" "${lvl_color_reset}"
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

### END LOGGING SNIPPET ###
