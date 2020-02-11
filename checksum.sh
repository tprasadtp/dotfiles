#!/usr/bin/env bash
#  Copyright (c) 2018-2020. Prasad Tengse
#

# This is a bash script to Generate checksums and sign them
# Version:1.0
# Author: Prasad Tengse
# Licence: MIT
# Requirements - Bash v4

set -eo pipefail
readonly SCRIPT=$(basename "$0")
readonly DIR="$(pwd)"
readonly CHECKSUMS_FILE="${DIR}/SHA512SUMS"
readonly YELLOW=$'\e[33m'
readonly GREEN=$'\e[32m'
readonly RED=$'\e[31m'
readonly NC=$'\e[0m'

function display_usage()
{
#Prints out help menu
cat <<EOF
Bash script to checksum and sign

Usage: ${YELLOW}${SCRIPT}   [options]${NC}
[-c --checksum]        [Generate SHA512 checksum file]
[-s --sign]            [GPG sign SHA512SUMS file]
[-v --verify]          [Verify SHA512 and GPG signatures]
[-G --skip-gpg-verify] [Skip verifying GPG signature]
[-h --help]            [Display this help message]

Note:
Fonts and git directory are excluded.
EOF
}


function print_info()
{
  printf "‣ %s \n" "$@"
}

function print_success()
{
  printf "%s✔ %s %s\n" "${GREEN}" "$@" "${NC}"
}

function print_warning()
{
  printf "%s⚠ %s %s\n" "${YELLOW}" "$@" "${NC}"
}

function print_error()
{
   printf "%s✖ %s %s\n" "${RED}" "$@" "${NC}"
}


function generate_checksums()
{
  print_info "Checksum will be saved as, SHA512SUMS"
  print_info "Any previous file by that name will be emptied"

  : > SHA512SUMS
  find . -type f \
			-not -path "./.git/**" \
      -not -path "./fonts/**" \
      -not -path "./github/**" \
			-not -path "./imtek-*/**" \
			-not -path "./emp-*/**" \
      -not -path "./vendor/**" \
      -not -path "./.github/**" \
      -not -name ".travis.yml" \
      -not -name "azure-pipelines.yml" \
      -not -name "SHA512SUMS" \
      -not -name ".gitignore" \
      -not -name "LICENSE.md" \
      -not -name "README.md" \
      -not -name "SHA512SUMS.asc" \
      "-print0" | xargs "-0" sha512sum \
        >> SHA512SUMS
  print_success "Generated SHA512 checksums"
}

function sign_checksum()
{
  if [[ -f $CHECKSUMS_FILE ]]; then
    print_info "Signing $CHECKSUMS_FILE"

    if gpg --armor --detach-sign \
      --output "${CHECKSUMS_FILE}.asc" \
      --yes --no-tty \
      "${CHECKSUMS_FILE}"; then
      print_success "Signed $CHECKSUMS_FILE"
    else
      print_error "Failed to sign $CHECKSUMS_FILE"
      exit 2
    fi
  else
    print_error "Checksumsfile not found!"
    exit 2
  fi
}

function verify_checksums() {
  print_info "Verifying SHA512SUMS"
  if [[ -f ${CHECKSUMS_FILE} ]]; then
		printf "%s" "${YELLOW}"
    if sha512sum -c "${CHECKSUMS_FILE}" --strict --quiet; then
			printf "%s" "${NC}"
      print_success "Hooray! SHA512 checksums verified"
    else
      print_error "Failed! Some files failed checksum verification!"
      print_error "Manually run 'sha512sum -c ${CHECKSUMS_FILE}' to check for errors."
      exit 2
    fi
  else
    print_error "File ${CHECKSUMS_FILE} not found!"
    exit 1
  fi
}

function verify_gpg_signature()
{
  # Verifies the file with its detached GPG signature.
  # Assumes that you already have public key in your keyring.
  # Assumes signature file is present at same localtion,
  # with same name but with .sig or .gpg or .asc extension.
  # Lets declare variables
  local checksum_sig_file
  # Checks if file is present
  if [ -f "${CHECKSUMS_FILE}.asc" ]; then
    checksum_sig_file="${CHECKSUMS_FILE}.asc"
  else
    print_error "Error! signature file not found!"
    exit 1;
  fi

  # Check for signature files
  print_info "Verifying digital signature of checksums"
  print_info "Signature File : ${checksum_sig_file}"
  print_info "Data File      : ${CHECKSUMS_FILE}"
  # Checks for commands
  if command -v gpg > /dev/null; then
    if gpg --verify "${checksum_sig_file}" "${CHECKSUMS_FILE}" 2>/dev/null; then
      print_success "Hooray! digintal signature verified"
    else
      print_error "Oh No! Signature checks failed!"
      exit 50;
    fi
  elif command -v gpgv > /dev/null; then
    if gpgv --keyring "$HOME/.gnupg/pubring.kbx" "${checksum_sig_file}" "${CHECKSUMS_FILE}"; then
      print_success "Signature verified"
    else
      print_error "Signature checks failed!!"
      exit 50;
    fi
  else
    print_error "Cannot perform verification. gpgv or gpg is not installed."
    print_error "This action requires gnugpg/gnupg2 or gpgv package."
    exit 1;
  fi
}

function main()
{
  # No args just run the setup function
  if [[ $# -eq 0 ]]; then
    print_error "No Action specified!"
    display_usage;
    exit 1
  fi

  while [[ ${1} != "" ]]; do
    case ${1} in
      -h | --help )           display_usage;exit 0;;
      -c | --checksum)        bool_gen_checksum="true";;
      -s | --sign)            bool_sign_checksum="true";;
      -v | --verify)          bool_verify_checksum="true";;
      -G | --skip-gpg-verify) bool_skip_gpg_verify="true";;
      * )                     echo -e "\e[91mInvalid argument(s). See usage below. \e[39m";display_usage;;
    esac
    shift
  done

  # Actions

  if [[ $bool_gen_checksum == "true" ]]; then
    print_info "Generating Checksums..."
    generate_checksums

    if [[ $bool_sign_checksum == "true" ]]; then
      sign_checksum
    else
      print_warning "Not Signing checksums file!"
    fi
  fi

  if [[ $bool_verify_checksum == "true" ]]; then
    verify_checksums
    if [[ $bool_skip_gpg_verify == "true" ]]; then
      print_warning "Skipping signature verification of checksums"
    else
      verify_gpg_signature
    fi
  fi

}

main "$@"
