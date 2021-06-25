# shellcheck shell=bash
#shellcheck disable=SC2164

set -e

SCRIPTPATH="$(
  cd -- "$(dirname "$0")" >/dev/null 2>&1
  pwd -P
)"
if [ -e $SCRIPTPATH/logger.sh ]; then
  #shellcheck source=/dev/null
  . "$SCRIPTPATH"/logger.sh
else
  echo "$SCRIPTPATH/logger.sh not found"
  exit 1
fi

log_trace "This is trace level"
log_trace "This is trace level"
log_trace "This is trace level"

log_debug "This is debug level"
log_debug "This is debug level"

log_info "This is info level"
log_info "This is info level"
log_info "This is info level"
log_info "This is info level"
log_info "This is info level"
log_info "This is info level"
log_info "This is info level"

log_success "This is success level"
log_notice "This is notice level"
log_warning "This is warning level"
log_error "This is error level"
