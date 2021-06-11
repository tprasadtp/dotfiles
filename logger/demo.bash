#!/bin/bash
#shellcheck disable=SC2164
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
if [[ -e $SCRIPTPATH/logger.bash ]]; then
  #shellcheck source=/dev/null
  source "$SCRIPTPATH"/logger.bash
else
  echo "$SCRIPTPATH/logger.bash not found"
  exit 1
fi

log_variable "LOG_FMT"
log_debug   "This is debug level"
log_info    "This is info level"
log_success "This is ok level"
log_notice  "This is notice level"
log_warning "This is warning level"
log_error   "This is error level"

log_step_variable "LOG_FMT"
log_step_debug    "This is debug level"
log_step_info     "This is info level"
log_step_success  "This is ok level"
log_step_notice   "This is notice level"
log_step_warning  "This is warning level"
log_step_error    "This is error level"
