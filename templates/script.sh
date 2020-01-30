#!/usr/bin/env bash

# This is a bash script to <>
# Version:1.0
# Author: Prasad Tengse
# Licence: MIT
# Github Repository: <GIT URL>
# Requirements - Bash v4.4 and above

#Constants
readonly DATE=$(date +%Y-%m-%d:%H:%M:%S)
readonly SCRIPT=$(basename "$0")
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 6)
readonly RED=$(tput setaf 1)
readonly NC=$(tput sgr 0)
readonly WIDTH=$(tput cols)
readonly VERSION="3.0.0 βeta"
readonly CURDIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
readonly spacing_string="%+11s"


function usage()
{
#Prints out help menu
cat <<EOF
Usage: $SCRIPT [options]

[-b --build]        [Build Something]
[-r --run]          [Run something]
[-h --help]         [Display this help message]
[-v --version]      [Display version info]
Github repo link : ${BLUE}https://github.com/tprasadtp/dotfiles${NC}
EOF
}


function print_info()
{
  printf "[  INFO   ] %s\n" "$@"
}


function print_success()
{
  tput setaf 10
  printf "[ SUCCESS ] %s\n" "$@"
  tput sgr 0
}


function print_warning()
{
  tput setaf 3
  printf "[  WARN   ] %s\n" "$@"
  tput sgr 0
}


function print_error()
{
  tput setaf 1
  printf "[  ERROR  ] %s\n" "$@"
  tput sgr 0
}

function display_version()
{
  print_info "Dotfiles Installation Script"
  # shellcheck disable=SC2059
  printf "${spacing_string} ${YELLOW} ${SCRIPT} ${NC}\n${spacing_string} ${YELLOW} ${VERSION} ${NC}\n" "Executable:" "Version:";
}



function main()
{
    #check if no args
  if [ $# -eq 0 ]; then
    print_error "No arguments found. See usage below."
    usage;
    exit 1;
  fi;

    # Process command line arguments.
  while [ "$1" != "" ]; do
    case ${1} in
      -b | --build )          echo "OK"
                              ;;
      -r | --run )            echo "OK";
                              exit 0
                              ;;
      -h |--h )               usage;
                              exit 0
                              ;;
      -v | --version)         display_version;
                              exit $?;
                              ;;
      * )                     printf_error "Invalid argument(s). See usage below."
                              usage;
                              exit 1
                              ;;
    esac
    shift
  done
}

#
main "$@"
