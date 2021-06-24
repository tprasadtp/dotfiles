#!/usr/bin/env bash
# Copyright (c) 2021. Prasad Tengse
#
# shellcheck disable=SC2155,SC2034

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


# Checks if command is available
function has_command() {
    if command -v "$1" >/dev/null; then
        return 0
    else
        return 1
    fi
    return 1
}

# Checks if dependencies are installed
function check_deps()
{
    local missing_deps=0

    if ! has_command git-chglog; then
        log_error "Missing git-chglog. Please install git-chglog (v0.11.2 and above)"
        log_info "from https://github.com/git-chglog/git-chglog."
        ((missing_deps++))
    else
        log_info "deps: git-chgog is available"
    fi

    if ! has_command git; then
        log_error "Missing git. Please install git"
        ((missing_deps++))
    else
        log_info "deps: git is available"
    fi

    if [[ $missing_deps -ne 0 ]]; then
        log_error "Missing one or more dependencies!"
        exit 2
    else
        log_info "deps: satisfied"
    fi
}



function build_regex()
{
    if [[ -n ${NEXT_TAG} ]]; then
        log_info "build-regex: using next tag - ${NEXT_TAG}"
        if git show-ref --tags --quiet --verify -- "refs/tags/${NEXT_TAG}"; then
            log_error "build-regex: next tag specified already exists in git"
            exit 1
        fi
        tag="$NEXT_TAG"
    else
        log_info  "build-regex: get closest tag"
        tag="$(git describe --tags --abbrev=0 2> /dev/null)"
        if [[ -z $tag ]]; then
            log_error "build-regex: there are no tags in this repository"
            log_error "build-regex: please use --next or create a tag"
            exit 1
        fi
    fi

    # validate tag is a valid semver tag
    if [[ ${tag} =~ $SEMVER_REGEX ]]; then
        log_info "build-regex: ${tag} is valid semver"
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        patch="${BASH_REMATCH[3]}"
        pre="${BASH_REMATCH[4]:1}"
        build="${BASH_REMATCH[8]:1}"
    else
        log_error "build-regex: ${tag} is not semver tag!"
        log_info "build-regex: all tags must be semver compatible"
        exit 1
    fi


    log_info "build-regex: tag major - $major"
    log_info "build-regex: tag minor - $minor"
    log_info "build-regex: tag patch - $patch"
    log_info "build-regex: tag pre   - $pre"
    log_info "build-regex: tag build - $build"

    # Build Regex to filter tags
    # https://regex101.com/r/0EiAvH/1/
    if [[ $pre == "" ]]; then
        tag_filter="[vV]?[\d]+\.[\d]+\.[\d]+\$"
    else
        tag_filter="^[vV]?(${major}\.${minor}\.${patch})(\-(alpha|beta|rc)(\.(0|[1-9][0-9]*))?)\$|(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\$"
    fi

    log_info "build-regex: chglog tag filter regex is ${tag_filter}"

}


function display_usage()
{
cat 1>&2 <<EOF
Changelog and Release Notes generation helper.

Usage: ${TEAL}${SCRIPT} ${BLUE} [options] ${NC}${VIOLET}
------------------------- Options ------------------------------${NC}
[-c | --changelog]        Generate changelog
[-R | --release-notes]    Generate release notes
${ORANGE}
---------------- Options with Required Argments-----------------${NC}
[-r | --repository]       Repository URL
                          (defaults to $PROJECT_SOURCE)
[-o | --output]           Save changelog to a file specified

[-n | --next]             Specify next version.
[--oldest-tag]            Oldest semver tag till which changelog
                          will be generated. This must exist and
                          has no effect on release-notes option.
[--header-file]           This file will be appended to begining of the
                          changelog.
[--footer-file]           This file will be appended to end of the
                          changelog.
${GRAY}
--------------------- Debugging & Help -------------------------${NC}
[-d | --debug]          Enable debug loggging
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



function main()
{
    if [[ $# -lt 1 ]]; then
      log_error "No arguments specified"
      display_usage
      exit 1
    fi

    while [[ ${1} != "" ]]; do
        case ${1} in
            -c | --changelog)       mode="changelog";;
            -R | --release-notes)   mode="release-notes";;
            # Options
            -r | --repository)      shift;PROJECT_SOURCE="${1}";;
            -n | --next)            readonly bool_use_next_mode="true";
                                    shift;readonly NEXT_TAG="${1}";;
            # Header and Footer Files
            -o | --output)          shift;readonly output_file="${1}";;
            --header-file)          shift;readonly header_file="${1}";;
            --footer-file)          shift;readonly footer_file="${1}";;
            # useful to merge old changelogs with autogenerated ones
            --oldest-tag)           shift;readonly oldest_tag="${1}";;
            # Debugging options
            --stderr)               LOG_TO_STDERR="true";;
            -d | --debug)           LOG_LVL="1";
                                    log_info "Enable verbose logging";;
            -h | --help )           display_usage;exit 0;;
            * )                     log_error "Invalid argument(s). See usage below.";
                                    display_usage;
                                    exit 1;
        esac
        shift
    done


    if [[ -z $mode ]]; then
      log_error "No mode specified!"
      display_usage
      exit 1
    fi

    if [[ -z $PROJECT_SOURCE ]]; then
        log_error "Repository URL is not defined!"
        log_error "Either define PROJECT_SOURCE or use --repository flag"
        display_usage
        exit 1
    fi

    # validate --next is a valid semver tag
    if [[ $bool_use_next_mode == "true" ]]; then
        if [[ ! $NEXT_TAG =~ $SEMVER_REGEX ]]; then
            log_error "main: --next tag $NEXT_TAG is invalid"
            exit 1
        else
            log_info "main: --next tag is valid semver tag"
        fi
    fi

    # Header file
    if [[ $header_file != "" ]]; then
        log_info "main: using header file: ${header_file}"
        if [[ ! -e $header_file ]]; then
            log_error "man: specified header file ${header_file} not found!"
            exit 1
        else
            readonly HEADER_FILE_CONTENTS="$(cat "$header_file")"
            if [[ -z $FOOTER_FILE_CONTENTS ]]; then
                log_error "main: footer file is empty!"
                exit 1
            fi
        fi
    fi

    # Footer file
    if [[ $footer_file != "" ]]; then
        log_info "main: using footer file: ${footer_file}"
        if [[ ! -e $footer_file ]]; then
            log_error "main: specified footer file ${footer_file} not found!"
            exit 1
        else
            readonly FOOTER_FILE_CONTENTS="$(cat "$footer_file")"
            if [[ -z $FOOTER_FILE_CONTENTS ]]; then
                log_error "main: footer file is empty!"
                exit 1
            fi
        fi
    fi

    # Output file is specified
    if [[ -n $output_file ]]; then
        output_dir="$(dirname "${output_file}")"
        log_info "main: output will be saved to dir=$output_dir, file=$(basename "$output_file")"
        if [[ ! -d ${output_dir} ]]; then
            log_error "output was specified but dir $output_dir does not exist!"
            exit 1
        fi
    fi

    # check if a git repo
    if [[ $(git rev-parse --is-inside-work-tree) != "true" ]]; then
        log_error "main: not a git repository!"
        exit 1
    fi

    # if oldest tag was specified
    if [[ -n $oldest_tag ]]; then
        log_info "main: will generate tags till oldest tag - $oldest_tag"
        if ! git show-ref --tags --quiet --verify -- "refs/tags/${oldest_tag}"; then
            log_error "main: oldest tag was specified but the tag does not exist in git!"
            exit 1
        fi
        readonly CHANGELOG_ARGS="$oldest_tag.."
    fi

    # check for deps
    check_deps

    # acquire_tag_tag
    build_regex

    if [[ $mode == "changelog" ]]; then
        log_info "main: generating changelog"

        if [[ -n ${NEXT_TAG} ]]; then
            CHANGELOG_CONTENT="$(git-chglog \
                --repository-url="${PROJECT_SOURCE}" \
                --next-tag="${NEXT_TAG}" \
                --tag-filter-pattern="${tag_filter}" \
                "${CHANGELOG_ARGS}")"
        else
            CHANGELOG_CONTENT="$(git-chglog \
                --repository-url="${PROJECT_SOURCE}" \
                --tag-filter-pattern="${tag_filter}" \
                "${CHANGELOG_ARGS}")"
        fi

        if [[ -z $CHANGELOG_CONTENT ]]; then
            log_error "main: failed to generate changelog"
            exit 1
        else
            if [[ -n $output_file ]]; then
                log_info "main: saving changelog to $output_file"
                echo "${HEADER_FILE_CONTENTS}${CHANGELOG_CONTENT}${FOOTER_FILE_CONTENTS}" > "${output_file}"
            else
                echo "${HEADER_FILE_CONTENTS}${CHANGELOG_CONTENT}${FOOTER_FILE_CONTENTS}"
            fi
        fi

    # release notes
    elif [[ $mode == "release-notes" ]]; then
        log_info "main: generating release notes"

        if [[ -n ${NEXT_TAG} ]]; then
            RN_CONTENT="$(git-chglog \
                --template "${REPO_ROOT:-.}/.chglog/RELEASE_NOTES.md.tpl" \
                --repository-url="${PROJECT_SOURCE}" \
                --next-tag="${NEXT_TAG}" \
                --tag-filter-pattern="${tag_filter}" \
                "${tag}")"
        else
            RN_CONTENT="$(git-chglog \
                --template "${REPO_ROOT:-.}/.chglog/RELEASE_NOTES.md.tpl" \
                --repository-url="${PROJECT_SOURCE}" \
                --tag-filter-pattern="${tag_filter}" \
                "${tag}")"
        fi

        if [[ -z $RN_CONTENT ]]; then
            log_error "main: failed to generate release notes"
            exit 1
        else
            if [[ -n $output_file ]]; then
                log_info "main: saving release notes to $output_file"
                echo "${HEADER_FILE_CONTENTS}${RN_CONTENT}" > "${output_file}"
            else
                echo "${HEADER_FILE_CONTENTS}${RN_CONTENT}"
            fi
        fi
    else
        log_error "main: invalid mode specified: $mode"
        exit 1
    fi

}

main "$@"

# diana:{diana_urn_flavor}:{remote}:{source}:{version}:{remote_path}:{type}
# diana:2:github:tprasadtp/templates::common/scripts/changelog.sh:static
