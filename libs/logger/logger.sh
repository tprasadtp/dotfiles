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

  # Get current indent level from global state.
  # We will discard it if its not valid integer
  case ${__LOG_CURRENT_INDENT_LEVEL} in
    '' | *[!0-9]*) local lvl_step="0" ;;
    *) local lvl_step="$__LOG_CURRENT_INDENT_LEVEL" ;;
  esac

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
  if [ "${LOG_FMT}" = "full" ] || [ "${LOG_FMT}" = "long" ] || [ "$lvl_colorized" = "false" ]; then
    # shellcheck disable=SC2155
    local lvl_prefix="$(date --rfc-3339=s)"
    local lvl_fmt="long"
  elif [ "${lvl_step}" -gt 0 ]; then
    local lvl_step_fmt_int="$((lvl_step * 2))"
    # shellcheck disable=SC2155
    local lvl_string="$(printf "%${lvl_step_fmt_int}s")•"
    local lvl_fmt="pretty"
  else
    local lvl_string="•"
    local lvl_fmt="pretty"
  fi

  # Define level, color and timestamp
  # By default we do not show log level and timestamp.
  # However, if LOG_FMT is set to "full" or "long" or if colors are disabled,
  # we will enable long format with timestamps
  case "$lvl_caller" in
    trace)
      [ "$lvl_fmt" = "long" ] && local lvl_string="$lvl_prefix [TRACE ]"
      # shellcheck disable=SC2155
      [ "$lvl_colorized" = "true" ] && local lvl_color="$(printf '\e[38;5;246m')"
      ;;
    debug)
      [ "$lvl_fmt" = "long" ] && local lvl_string="$lvl_prefix [DEBUG ]"
      # shellcheck disable=SC2155
      [ "$lvl_colorized" = "true" ] && local lvl_color="$(printf '\e[38;5;250m')"
      ;;
    info)
      [ "$lvl_fmt" = "long" ] && local lvl_string="$lvl_prefix [INFO  ]"
      ;;
    success)
      [ "$lvl_fmt" = "long" ] && local lvl_string="$lvl_prefix [OK    ]"
      # shellcheck disable=SC2155
      [ "$lvl_colorized" = "true" ] && local lvl_color="$(printf '\e[38;5;83m')"
      ;;
    warning)
      [ "$lvl_fmt" = "long" ] && local lvl_string="$lvl_prefix [WARN  ]"
      # shellcheck disable=SC2155
      [ "$lvl_colorized" = "true" ] && local lvl_color="$(printf '\e[38;5;214m')"
      ;;
    notice)
      [ "$lvl_fmt" = "long" ] && local lvl_string="$lvl_prefix [NOTICE]"
      # shellcheck disable=SC2155
      [ "$lvl_colorized" = "true" ] && local lvl_color="$(printf '\e[38;5;81m')"
      ;;
    error)
      [ "$lvl_fmt" = "long" ] && local lvl_string="$lvl_prefix [ERROR ]"
      # shellcheck disable=SC2155
      [ "$lvl_colorized" = "true" ] && local lvl_color="$(printf '\e[38;5;197m')"
      ;;
    *)
      [ "$lvl_fmt" = "long" ] && local lvl_string="$lvl_prefix [UNKOWN]"
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

log_increment_indent()
{
  case "${__LOG_CURRENT_INDENT_LEVEL:-0}" in
    '' | *[!0-9]*) __LOG_CURRENT_INDENT_LEVEL="1" ;;
    *) __LOG_CURRENT_INDENT_LEVEL="$((__LOG_CURRENT_INDENT_LEVEL + 1))" ;;
  esac
}

log_add_indent()
{
  log_increment_indent
}

log_decrement_indent()
{
  case "${__LOG_CURRENT_INDENT_LEVEL:-0}" in
    *[0-9]*) __LOG_CURRENT_INDENT_LEVEL="$((__LOG_CURRENT_INDENT_LEVEL - 1))" ;;
    *) __LOG_CURRENT_INDENT_LEVEL="0" ;;
  esac
}

log_reset_indent()
{
  __LOG_CURRENT_INDENT_LEVEL="0"
}
