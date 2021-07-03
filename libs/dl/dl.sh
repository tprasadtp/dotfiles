# shellcheck shell=sh
# shellcheck disable=SC3043

# SHELL DOWNLOAD LIBRARY
# - DEPENDS ON LOGGING LIBRARY
# - Requires WGET OR CURL
# - Requires sha256 command to be avilable (wither from coreutils or openssl)
# - Requires gpgv or gpg command to  be available, if gpg key is binary
# - Requires gpg if gpg key is in ascii armored file
# See https://github.com/tprasadtp/shlibs/dl/README.md
# If included in other files, contents between snippet markers is
# automatically updated and all changes between markers will be ignored.

# ERRORS
__libdl_print_error()
{
  # we reserve err code 3 for this func itself
  if [ -z "${1}" ] || [ "$#" -ne 1 ] || [ "${1}" -eq 3 ]; then
    return 3
  fi

  case ${1} in
    # Dependency errors
    # Assume we do not have logging functions available either.
    2)
      printf "[ERROR ] Dependency Error.\n"
      printf "[ERROR ] This script requires logger library from https://github.com/tprasadtp/shlibs/logger\n"
      printf "[ERROR ] Please source it before using dl library.\n"
      ;;

    11)
      log_error "Internal Error!"
      log_error "Please report this error to https://github.com/tprasadtp/shlibs"
      log_error "Please include Outputs of following commands in your error reports"
      log_error "1. uname -m"
      log_error "2. uname -r"
      log_error "3. curl --version"
      log_error "4. wget --version"
      ;;

    12)
      log_error "Internal Error! Invalid arguments!"
      ;;

    21)
      log_error "This script requires curl or wget, but both of them were not installed or not available."
      if [ -n "$LOADEDMODULES" ] && __libdl_has_command "module"; then
        log_error "If using LMOD & MATLAB, it can interfere with curl libraries(libcurl) on CentOS 7/RHEL-7/MacOS"
        log_error "Please unload all modules via - module purge, before running this script."
      fi
      ;;

    22)
      log_error "Cannot find any of: sha256sum, gsha256sum or openssl, which is required by checksum verification."
      # shellcheck disable=SC2155
      local __libdl_errmap_os="$(libdl_get_GOOS)"
      case $__libdl_errmap_os in
        Linux)
          log_error "sha256sum is provided by package coreutils. Install it via package manager."
          ;;
        Darwin)
          log_error "sha256sum is not available by default, install coreutils or openssl via Homebrew"
          ;;
      esac
      ;;

    24)
      log_error "Cannot find command gpg which is required for signature verification."
      # shellcheck disable=SC2155
      local __libdl_errmap_os="$(libdl_get_GOOS)"
      case $__libdl_errmap_os in
        Linux)
          log_error "Command gpg is usually provided by package gnupg or gpg. Install it via package manager."
          ;;
        Darwin)
          log_error "Please install gnupg via Homebrew - brew install gnupg"
          ;;
      esac
      ;;
    # Checksum Local Errors
    31) log_error "Target file not found or not accesible." ;;
    32) log_error "Checksum file was not found or not accessible." ;;
    33) log_error "Failed to caclulate checksum for unknown reasons" ;;
    34) log_error "Checksum hash is invalid" ;;
    35) log_error "Checksum file is missing hashes for the target specified" ;;

    # Checksum remote errors
    40) log_error "GPG signature verification was enabled but GPG ID/ Key file or key file URL was not specified" ;;

    # Path errors
    50) log_error "Temp dir is not writable or tempdir creation failed" ;;
    51) log_error "Destination file/directory is not writable" ;;
    52) log_error "Destination directory directory does not exist" ;;
    53) log_error "Destination file exists and checksum verification is not enabled, Must use --overwrite or --force" ;;

    # Download Errors
    61) log_error "Checksum verification was enabled via remote file, but failed to fetch it after multiple attempts!" ;;
    62) log_error "GPG singature verification was enabled remote key file, but failed to fetch it after multiple attempts!" ;;
    # HTTP page not retrieved. The requested url was not found or returned another error with the HTTP error code being
    # 400 or above. This return code only appears if -f, --fail is used
    71) log_error "Asset not found! Server returned a 4XX error!" ;;
    72) log_error "Asset download failed. (Generic Error)!" ;;

    80) log_error "Checksum verification failed!" ;;
    81) log_error "GPG signature check failed!" ;;

    # IOErrors
    90) log_error "Failed to replace existing binary" ;;
    91) log_error "Failed to cleanup temporary files" ;;

    # Exception
    *) log_error "Unknown error: ${1}" ;;
  esac
}

# convert `uname -m` to GOARCH and output
# By default function will try to map current uname -m to GOARCH.
# You can optionally pass it as an argument (useful in remote mounted filesystems)
# If cannot convert will return code is 1
__libdl_GOARCH()
{
  local arch
  arch="${1:-$(uname -m)}"
  case $arch in
    x86_64)
      printf "amd64"
      return 0
      ;;
    x86 | i686 | i386)
      printf "386"
      return 0
      ;;
    aarch64)
      printf "arm64"
      return 0
      ;;
    armv5* | armv6* | armv7* | armv8*)
      printf "arm"
      return 0
      ;;
  esac
  # We failed to map architectures to GOARCH
  return 1
}

# convert `uname -m` to GOARM and output
# By default function will try to map current uname -m to GOARM.
# You can optionally pass it as an argument (useful in remote mounted filesystems)
# If cannot convert will output empty string!
__libdl_GOARM()
{
  local arch
  arch="${1:-$(uname -m)}"
  case $arch in
    armv7*)
      printf "v7"
      ;;
    armv6*)
      printf "v6"
      ;;
    armv5*)
      printf "v5"
      ;;
  esac
}

# Maps os name to GOOS
# By default function will try to map current uname -s to GOARCH.
# You can optionally pass it as an argument (useful in remote mounted mounted filesystems)
# Returns 0 and printfs GOOS if supported OS was detected
# otherwise returns 1 and nothing
__libdl_GOOS()
{
  local os
  os="${1:-$(uname -s)}"
  case "$os" in
    Linux)
      printf "linux"
      return 0
      ;;
    Darwin)
      printf "darwin"
      return 0
      ;;
    CYGWIN_NT* | Windows_NT | MSYS_NT* | MINGW*)
      printf "windows"
      return 0
      ;;
    FreeBSD)
      printf "freebsd"
      return 0
      ;;
  esac
  return 1
}

# Check if is a function
# Used for checking imported/sourced logging library
# This is not fool proof as cleverly named aliases
# and binaries can evaluate to true.
__libdl_is_function()
{
  case "$(type -- "$1" 2>/dev/null)" in
    *function*) return 0 ;;
  esac
  return 1
}

# checks if all dependency functions are avilable
# We do not check functions in this file as its 99.99% of the cases useless
__libdl_has_depfuncs()
{
  local missing="0"
  if ! __libdl_is_function "log_trace"; then
    missing="$((missing + 1))"
  fi

  if ! __libdl_is_function "log_debug"; then
    missing="$((missing + 1))"
  fi

  if ! __libdl_is_function "log_info"; then
    missing="$((missing + 1))"
  fi

  if ! __libdl_is_function "log_success"; then
    missing="$((missing + 1))"
  fi

  if ! __libdl_is_function "log_warning"; then
    missing="$((missing + 1))"
  fi

  if ! __libdl_is_function "log_notice"; then
    missing="$((missing + 1))"
  fi

  if ! __libdl_is_function "log_error"; then
    missing="$((missing + 1))"
  fi

  return "$missing"
}

# Checks if command is available
__libdl_has_command()
{
  if command -v "$1" >/dev/null; then
    return 0
  else
    return 1
  fi
  return 1
}

# Checks if curl is available
__libdl_has_curl()
{
  if __libdl_has_command curl; then
    if curl --version >/dev/null 2>&1; then
      return 0
    else
      return 1
    fi
  fi
  return 1
}

# Checks if wget is available
__libdl_has_wget()
{
  if __libdl_has_command wget; then
    if wget --version >/dev/null 2>&1; then
      return 0
    else
      return 2
    fi
  fi
  return 1
}

# Checks if gpgv is available
__libdl_has_gpgv()
{
  if __libdl_has_command gpgv; then
    if gpgv --version >/dev/null 2>&1; then
      return 0
    else
      return 2
    fi
  fi
  return 1
}

# Checks if gpg is available
__libdl_has_gpg()
{
  if __libdl_has_command gpg; then
    if gpg --version >/dev/null 2>&1; then
      return 0
    else
      return 2
    fi
  fi
  return 1
}

# SHA256 hash a file
# Returns sha256 hash and return code 0 if successful
__libdl_hash_sha256()
{
  local target="${1}"
  local hasher_exe="${2}"
  local hash

  if [ "$#" -gt 3 ] || [ "$#" -lt 1 ]; then
    return 12
  fi

  if [ -z "$target" ] || [ "$target" = "" ]; then
    return 12
  fi

  if [ ! -e "$target" ]; then
    return 31
  fi

  # Hash handler
  if [ -z "$hasher_exe" ] || [ "${hasher_exe}" = "auto" ]; then
    # macOS homebrew
    if __libdl_has_command gsha256sum; then
      hasher_exe="gsha256sum"
    # coreutils/busybox
    elif __libdl_has_command sha256sum; then
      hasher_exe="sha256sum"
    elif __libdl_has_command shasum; then
      # Darwin, freebsd
      hasher_exe="shasum"
    elif __libdl_has_command rhash; then
      hasher_exe="rhash"
    fi
  fi

  # Hasher
  case $hasher_exe in
    gsha256sum) hash="$(gsha256sum "$target")" || return 33 ;;
    sha256sum) hash="$(sha256sum "$target")" || return 33 ;;
    shasum) hash="$(shasum -a 256 "$target" 2>/dev/null)" || return 33 ;;
    rhash) hash="$(rhash --sha256 "$target")" || return 33 ;;
    *) return 22 ;;
  esac

  # Post processor to extract hash
  # Checksum output is usually <HASH><space><binary-indicator|space><File>
  hash="${hash% *}"
  hash="${hash% *}"

  if __libdl_is_sha256hash "${hash}"; then
    printf "%s" "$hash"
  else
    return 33
  fi
}

# check if given string is a sha256 hash
# return 0 if true 1 otherwise
__libdl_is_sha256hash()
{
  local hash="${1}"
  if printf "%s" "$hash" | grep -qE '^[a-f0-9]{64}$'; then
    return 0
  else
    return 1
  fi
}

# check if given string is a sha512 hash
# return 0 if true 1 otherwise
__libdl_is_sha512hash()
{
  local hash="${1}"
  if printf "%s" "$hash" | grep -qE '^[a-f0-9]{128}$'; then
    return 0
  else
    return 1
  fi
}

# Verifies a hash by comparing it with checksum file or a raw hash
# This function produces some output which is not machine readable
# Status codes should be used instead of output which is intended for
# console use and logging.
__libdl_hash_sha256_verify()
{
  local target="$1"
  local hash="$2"

  if [ "$#" -ne 2 ]; then
    return 12
  fi

  log_trace "Target File   : ${target}"
  log_trace "Hash          : ${hash}"

  # Check if target exists
  if [ -z "$target" ]; then
    log_error "No target file specified!"
    return 31
  fi

  if [ ! -e "$target" ]; then
    log_error "File not found - $target"
    return 31
  fi

  local mode
  if __libdl_is_sha256hash "$hash"; then
    mode="hash-raw"
  else
    mode="hash-file"
  fi

  local target_basename want got
  # If verifier is hash file, check if it exists
  if [ $mode == "hash-file" ]; then
    if [ ! -e "$hash" ]; then
      log_error "Checksum file not found: ${hash}"
      return 32
    fi
    # http://stackoverflow.com/questions/2664740/extract-file-basename-without-path-and-extension-in-bash
    target_basename=${target##*/}
    want="$(grep "${target_basename}" "${hash}" 2>/dev/null | tr '\t' ' ' | cut -d ' ' -f 1)"
    # if file does not exist $want will be empty
    if ! __libdl_is_sha256hash "$want"; then
      log_error "Error! Failed to find hash corresponding to '$target_basename' in file $hash"
      return 35
    fi
  else
    # Raw hash string
    want="$hash"
  fi

  local hash_rc
  got=$(__libdl_hash_sha256 "$target")
  hash_rc="$?"

  if [ $hash_rc -ne 0 ]; then
    log_error "An error occured while caclulating checksum for file - ${target}"
    return $hash_rc
  else
    log_trace "Target Hash   : ${got}"
    log_trace "Expected Hash : ${want}"
    if [ "$want" != "$got" ]; then
      log_error "SHA256 hash for '$target' did not match!"
      log_error "Expected : ${want}"
      log_error "Got      : ${got}"
      return 80
    else
      return 0
    fi
  fi
}

# Main download file handler.
# This will be called recursively if checksum and gpg keys are remote.
# URLs supports placeholders for GOOS and GOARCH
# Include %GOOS% %GOARCH% %GOARM% in your URL string to replace with GOOS and GOARCH values
download_file()
{
  local remote_url local_file
  local checksum
  local gpg_key

  local checksum_enable="0"
  local gpg_enable="0"

  local force="0"

  if [ "$#" -lt 4 ]; then
    return 11
  fi

  while [ "${1}" != "" ]; do
    case ${1} in
      --url)
        shift
        remote_url="${1}"
        ;;
      --local-file)
        shift
        local_file="${1}"
        ;;
      --checksum)
        shift
        checksum_enable=1
        checksum="${1}"
        ;;
      --gpg-key)
        shift
        gpg_enable=1
        gpg_key="${1}"
        ;;
      --force)
        shift
        force=1
        ;;
      *) return 12 ;;
    esac
    shift
  done

  # url basic validity checks
  if [ -z "${url}" ]; then
    return 30
  else
    case ${url} in
      https://* | http://*) ;;
      *) return 30 ;;
    esac
  fi

  # destination path check
  if [ -z ${local_file} ] || [ ! -w "$(dirname "${local_file}")" ]; then
    return 31
  fi

}
