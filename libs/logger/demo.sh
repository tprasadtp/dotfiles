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

log_debug "This is trace level"
log_debug "This is debug level"
log_info "This is info level"
log_success "This is success level"
log_notice "This is notice level"
log_warning "This is warning level"
log_error "This is error level"

log_add_indent
log_trace "This is indent=1 trace level" "With extra message filed"
log_debug "This is indent=1 debug level" "With extra message filed"
log_info "This is indent=1 info level" "With extra message filed"
log_success "This is indent=1 success level" "With extra message filed"
log_warning "This is indent=1 warning level" "With extra message filed"
log_notice "This is indent=1 notice level" "With extra message filed"
log_error "This is indent=1 error level" "With extra message filed"

log_add_indent
log_trace "This is indent=2 trace level" "With extra message filed"
log_debug "This is indent=2 debug level" "With extra message filed"
log_info "This is indent=2 info level" "With extra message filed"
log_success "This is indent=2 success level" "With extra message filed"
log_warning "This is indent=2 warning level" "With extra message filed"
log_notice "This is indent=2 notice level" "With extra message filed"
log_error "This is indent=2 error level" "With extra message filed"

log_add_indent
log_trace "This is indent=3 trace level" "With extra message filed"
log_debug "This is indent=3 debug level" "With extra message filed"
log_info "This is indent=3 info level" "With extra message filed"
log_success "This is indent=3 success level" "With extra message filed"
log_warning "This is indent=3 warning level" "With extra message filed"
log_notice "This is indent=3 notice level" "With extra message filed"
log_error "This is indent=3 error level" "With extra message filed"

log_reset_indent

log_trace "This is indent=reset trace level" "With extra message filed"
log_debug "This is indent=reset debug level" "With extra message filed"
log_info "This is indent=reset info level" "With extra message filed"
log_success "This is indent=reset success level" "With extra message filed"
log_warning "This is indent=reset warning level" "With extra message filed"
log_notice "This is indent=reset notice level" "With extra message filed"
log_error "This is indent=reset error level" "With extra message filed"

log_add_indent
log_add_indent
log_decrement_indent
log_trace "This is indent=1 trace level" "With extra message filed"
log_debug "This is indent=1 debug level" "With extra message filed"
log_info "This is indent=1 info level" "With extra message filed"
log_success "This is indent=1 success level" "With extra message filed"
log_warning "This is indent=1 warning level" "With extra message filed"
log_notice "This is indent=1 notice level" "With extra message filed"
log_error "This is indent=1 error level" "With extra message filed"

log_reset_indent
log_add_indent
log_add_indent
log_add_indent
log_add_indent
log_add_indent
log_trace "This is indent=5 trace level" "With extra message filed"
log_debug "This is indent=5 debug level" "With extra message filed"
log_info "This is indent=5 info level" "With extra message filed"
log_success "This is indent=5 success level" "With extra message filed"
log_warning "This is indent=5 warning level" "With extra message filed"
log_notice "This is indent=5 notice level" "With extra message filed"
log_error "This is indent=5 error level" "With extra message filed"
