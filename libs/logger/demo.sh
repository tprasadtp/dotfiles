# shellcheck shell=bash
#shellcheck disable=SC2164

set -e

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
if [[ -e $SCRIPTPATH/logger.sh ]]; then
  #shellcheck source=/dev/null
  source "$SCRIPTPATH"/logger.sh
else
  echo "$SCRIPTPATH/logger.sh not found"
  exit 1
fi

log_variable "LOG_FMT"
log_debug   "This is debug level"
log_info    "This is info level"
log_success "This is success level"
log_notice  "This is notice level"
log_warning "This is warning level"
log_error   "This is error level"

log_step_variable "LOG_FMT_STEP"
log_step_debug    "This is step_debug level"
log_step_info     "This is step_info level"
log_step_success  "This is step_success level"
log_step_notice   "This is step_notice level"
log_step_warning  "This is step_warning level"
log_step_error    "This is step_error level"
