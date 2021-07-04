# shellcheck shell=sh
# shellcheck disable=SC3043

# SHELL DOWNLOAD LIBRARY
# - DEPENDS ON LOGGING LIBRARY
# - Requires wget/curl
#
# - For checksum verification:
#   - gsha256sum/sha256sum/shasum/rhash - for SHA256
#   - gsha512sum/sha512sum/shasum/rhash - for SHA512
#   - gsha1/sha1sum/shasum/rhash        - for SHA1
#   - gmd5sum/md5sum/rhash              - for MD5
#
# - For signature verification
#   - gpgv or gpg command               - if gpg key is binary
#   - gpg                               - if gpg key is in ascii armored file
# See https://github.com/tprasadtp/shlibs/dl/README.md
# If included in other files, contents between snippet markers is
# automatically updated and all changes between markers will be ignored.

# ERRORS
__libdl_print_error()
{

  local err_code="${1:-0}"

  case ${err_code} in
    0) ;;
    # Dependency errors
    # Assume we do not have logging functions available either.
    2)
      printf "[ERROR ] Dependency Error.\n"
      printf "[ERROR ] This script requires logger library from https://github.com/tprasadtp/shlibs/logger\n"
      printf "[ERROR ] Please source it before using dl library.\n"
      ;;
    3)
      log_error "Invalid, unsupported or not enough arguments"
      ;;
    4)
      log_error "URL specified is empty of invalid!"
      ;;

    11)
      log_error "GOOS/GOARCH Mapper error!"
      log_error "Please report this error to https://github.com/tprasadtp/shlibs"
      log_error "Please include outputs of following commands in your error reports"
      log_error "1. uname -m"
      log_error "2. uname -r"
      ;;

    12)
      log_error "Internal Error! Invalid arguments!"
      ;;

    21)
      log_error "This script requires curl or wget, but both of them were not installed or not available."
      if [ -n "$LOADEDMODULES" ] && __libdl_has_command "module"; then
        log_error "If using LMOD & MATLAB, it can interfere with curl libraries(libcurl) on CentOS 7/RHEL-7/macOS"
        log_error "Please unload all modules via - module purge, before running this script."
      fi
      ;;

    22)
      log_error "Cannot find any of: sha256sum, gsha256sum, shasum rhash, required for SHA256 checksum verification."
      # shellcheck disable=SC2155
      local __libdl_errmap_os="$(libdl_get_GOOS)"
      case $__libdl_errmap_os in
        Linux)
          log_error "sha256sum is provided by package coreutils. Install it via package manager."
          ;;
        Darwin)
          log_error "sha256sum is not available by default, install coreutils via Homebrew"
          ;;
      esac
      ;;

    23)
      log_error "Cannot find any of: sha512sum, gsha512sum, shasum or rhash, required for SHA512 checksum verification."
      # shellcheck disable=SC2155
      local __libdl_errmap_os="$(libdl_get_GOOS)"
      case $__libdl_errmap_os in
        Linux)
          log_error "sha512sum is provided by package coreutils. Install it via package manager."
          ;;
        Darwin)
          log_error "sha512sum is not available by default, install coreutils via Homebrew"
          ;;
      esac
      ;;

    24)
      log_error "Cannot any any of: sha1sum, gsha1sum or rhash, Required for SHA1 checksum verification."
      # shellcheck disable=SC2155
      local __libdl_errmap_os="$(libdl_get_GOOS)"
      case $__libdl_errmap_os in
        Linux)
          log_error "sha1sum is provided by package coreutils or busybox. Install it via package manager."
          ;;
        Darwin)
          log_error "sha1sum should be available by default. Alternatively install coreutils via Homebrew"
          ;;
      esac
      ;;

    25)
      log_error "Cannot any any of: md5sum, rhash, Required for MD5 checksum verification."
      # shellcheck disable=SC2155
      local __libdl_errmap_os="$(libdl_get_GOOS)"
      case $__libdl_errmap_os in
        Linux)
          log_error "md5sum is provided by package coreutils or busybox. Install it via package manager."
          ;;
        Darwin)
          log_error "md5sum should be available by default. Alternatively install coreutils via Homebrew"
          ;;
      esac
      ;;

    26)
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
    # Checksum Errors
    31) log_error "Target file not found or not accesible." ;;
    32) log_error "Checksum file was not found or not accessible." ;;
    33) log_error "Failed to caclulate checksum for unknown reasons" ;;
    34) log_error "Checksum hash is invalid" ;;
    35) log_error "Checksum file is missing hashes for the target specified" ;;
    36) log_error "Unsupported hash algorithm. Only sha256 and sha512 are supported" ;;

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

    # Unknown
    *) log_error "Unknown error: ${err_code}" ;;
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
    CYGWIN_NT* | Windows_NT* | MSYS_NT* | MINGW*)
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

  if ! __libdl_is_function "log_warn"; then
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

## File hashers
## -------------------------------------------------------

# MD5 hash a file
# Returns MD5 hash and return code 0 if successful
__libdl_hash_md5()
{
  local target="${1}"
  local hasher_exe="${2:-auto}"
  local hash

  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
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
    if __libdl_has_command gmd5sum; then
      hasher_exe="gmd5sum"
    # coreutils/busybox
    elif __libdl_has_command md5sum; then
      hasher_exe="md5sum"
    elif __libdl_has_command rhash; then
      hasher_exe="rhash"
    fi
  fi

  # Hasher
  case $hasher_exe in
    gmd5sum) hash="$(gmd5sum "$target")" || return 33 ;;
    md5sum) hash="$(md5sum "$target")" || return 33 ;;
    rhash) hash="$(rhash --md5 "$target")" || return 33 ;;
    *) return 22 ;;
  esac

  # Post processor to extract hash
  # Checksum output is usually <HASH><space><binary-indicator|space><File>
  hash="${hash%% *}"

  if __libdl_is_md5hash "${hash}"; then
    printf "%s" "$hash"
  else
    return 33
  fi
}

# MD5 hash a file
# Returns MD5 hash and return code 0 if successful
__libdl_hash_sha1()
{
  local target="${1}"
  local hasher_exe="${2:-auto}"
  local hash

  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
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
    if __libdl_has_command gsha1sum; then
      hasher_exe="gsha1sum"
    # coreutils/busybox
    elif __libdl_has_command sha1sum; then
      hasher_exe="sha1sum"
    elif __libdl_has_command shasum; then
      # Darwin, freebsd
      hasher_exe="shasum"
    elif __libdl_has_command rhash; then
      hasher_exe="rhash"
    fi
  fi

  # Hasher
  case $hasher_exe in
    gsha1sum) hash="$(gsha1sum "$target")" || return 33 ;;
    sha1sum) hash="$(sha1sum "$target")" || return 33 ;;
    shasum) hash="$(shasum -a 1 "$target" 2>/dev/null)" || return 33 ;;
    rhash) hash="$(rhash --sha1 "$target")" || return 33 ;;
    *) return 22 ;;
  esac

  # Post processor to extract hash
  # Checksum output is usually <HASH><space><binary-indicator|space><File>
  hash="${hash%% *}"

  if __libdl_is_sha1hash "${hash}"; then
    printf "%s" "$hash"
  else
    return 33
  fi
}

# SHA256 hash a file
# Returns sha256 hash and return code 0 if successful
__libdl_hash_sha256()
{
  local target="${1}"
  local hasher_exe="${2:-auto}"
  local hash

  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
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
  hash="${hash%% *}"

  if __libdl_is_sha256hash "${hash}"; then
    printf "%s" "$hash"
  else
    return 33
  fi
}

# SHA512 hash a file
# Returns sha512 hash and return code 0 if successful
__libdl_hash_sha512()
{
  local target="${1}"
  local hasher_exe="${2:-auto}"
  local hash

  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
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
    if __libdl_has_command gsha512sum; then
      hasher_exe="gsha512sum"
    # coreutils/busybox
    elif __libdl_has_command sha512sum; then
      hasher_exe="sha512sum"
    elif __libdl_has_command shasum; then
      # Darwin, freebsd
      hasher_exe="shasum"
    elif __libdl_has_command rhash; then
      hasher_exe="rhash"
    fi
  fi

  # Hasher
  case $hasher_exe in
    gsha512sum) hash="$(gsha512sum "$target")" || return 33 ;;
    sha512sum) hash="$(sha512sum "$target")" || return 33 ;;
    shasum) hash="$(shasum -a 512 "$target" 2>/dev/null)" || return 33 ;;
    rhash) hash="$(rhash --sha512 "$target")" || return 33 ;;
    *) return 22 ;;
  esac

  # Post processor to extract hash
  # Checksum output is usually <HASH><space><binary-indicator|space><File>
  hash="${hash%% *}"

  if __libdl_is_sha512hash "${hash}"; then
    printf "%s" "$hash"
  else
    return 33
  fi
}

## Hash Validators
## --------------------------------------------

# check if given string is a md5 hash
# return 0 if true 1 otherwise
__libdl_is_md5hash()
{
  local hash="${1}"
  if printf "%s" "$hash" | grep -qE '^[a-f0-9]{32}$'; then
    return 0
  else
    return 1
  fi
}

# check if given string is a sha1 hash
# return 0 if true 1 otherwise
__libdl_is_sha1hash()
{
  local hash="${1}"
  if printf "%s" "$hash" | grep -qE '^[a-f0-9]{40}$'; then
    return 0
  else
    return 1
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
__libdl_verify_hash()
{
  local target="$1"
  local hash="$2"
  local algorithm="${3}"

  if [ "$#" -ne 3 ]; then
    return 12
  fi

  log_trace "Target File   : ${target}"
  log_trace "Hash          : ${hash}"
  log_trace "Type          : ${algorithm}"

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
  local hash_type

  case ${algorithm} in
    sha256 | sha-256 | SHA256 | SHA-256)
      if __libdl_is_sha256hash "$hash"; then
        mode="hash-raw"
      else
        mode="hash-file"
      fi
      hash_type="sha256"
      ;;
    sha512 | sha-512 | SHA512 | SHA-512)
      if __libdl_is_sha512hash "$hash"; then
        mode="hash-raw"
      else
        mode="hash-file"
      fi
      hash_type="sha512"
      ;;
    sha1 | sha-1 | SHA1 | SHA-1)
      if __libdl_is_sha1hash "$hash"; then
        mode="hash-raw"
      else
        mode="hash-file"
      fi
      hash_type="sha1"
      ;;
    md5 | md-5 | MD5 | MD-5)
      if __libdl_is_md5hash "$hash"; then
        mode="hash-raw"
      else
        mode="hash-file"
      fi
      hash_type="md5"
      ;;
    *)
      log_error "Unsupported hash algorithm - ${algorithm}"
      return 36
      ;;
  esac

  local hash_rc
  local target_basename
  local want got

  # If verifier is hash file, check if it exists
  if [ $mode = "hash-file" ]; then
    if [ ! -e "$hash" ]; then
      log_error "Checksum file not found: ${hash}"
      return 32
    fi
    # http://stackoverflow.com/questions/2664740/extract-file-basename-without-path-and-extension-in-bash
    target_basename=${target##*/}
    want="$(grep "${target_basename}" "${hash}" 2>/dev/null)"
    # we got hash and filename we need to remove extra stuff and just get the hash
    # Checksum output is usually <HASH><space><binary-indicator|space><File>
    want="${want%% *}"

    # if file does not exist $want will be empty
    case ${hash_type} in
      sha256)
        if ! __libdl_is_sha256hash "$want"; then
          log_error "Error! Failed to find SHA256 hash corresponding to '$target_basename' in file $hash"
          return 35
        fi
        # Caclulate SHA256 hash of target file
        got=$(__libdl_hash_sha256 "$target")
        hash_rc="$?"
        ;;
      sha512)
        if ! __libdl_is_sha512hash "$want"; then
          log_error "Error! Failed to find SHA512 hash corresponding to '$target_basename' in file $hash"
          return 35
        fi
        # Caclulate SHA512 hash of target file
        got=$(__libdl_hash_sha512 "$target")
        hash_rc="$?"
        ;;
      sha1)
        if ! __libdl_is_sha1hash "$want"; then
          log_error "Error! Failed to find SHA1 hash corresponding to '$target_basename' in file $hash"
          return 35
        fi
        # Caclulate SHA512 hash of target file
        got=$(__libdl_hash_sha1 "$target")
        hash_rc="$?"
        ;;
      md5)
        if ! __libdl_is_md5hash "$want"; then
          log_error "Error! Failed to find MD5 hash corresponding to '$target_basename' in file $hash"
          return 35
        fi
        # Caclulate SHA512 hash of target file
        got=$(__libdl_hash_md5 "$target")
        hash_rc="$?"
        ;;
      *)
        log_error "Unsupported hash algorithm - ${algorithm}"
        return 36
        ;;
    esac

  else
    # Raw hash string
    want="$hash"
  fi

  if [ $hash_rc -ne 0 ]; then
    log_error "An error occured while caclulating hash(${algorithm}) for file - ${target}"
    return $hash_rc
  else
    if [ "$want" != "$got" ]; then
      log_error "Hash(${algorithm}) for '$target' did not match!"
      log_error "Expected : ${want}"
      log_error "Got      : ${got}"
      return 80
    else
      log_error "Hash(${algorithm}) for '$target' verified"
      log_trace "Target Hash   : ${got}"
      log_trace "Expected Hash : ${want}"
      return 0
    fi
  fi
}

# Render URL
__libdl_get_rendered_string()
{
  local url="${1}"
  local goos goarch goarm version uname_s uname_m

  # Template rendering:GOOS
  case $url in
    *++GOOS++*)
      if __libdl_GOOS >/dev/null; then
        goos="$(__libdl_GOOS)"
        # This would have been ideal, with
        # url="${url//++GOOS++/${goos}}",
        # but posix sh lacks // param substititution.
        # It is highly unlikely that printf would fail,
        # avoiding PIPEFAIL issues
        url="$(printf "%s" "${url}" | sed -e "s/++GOOS++/${goos}/g")"
      else
        return 11
      fi
      ;;
  esac

  # Template rendering:GOARCH
  case $url in
    *++GOARCH++*)
      if __libdl_GOARCH >/dev/null; then
        goarch="$(__libdl_GOARCH)"
        url="$(printf "%s" "${url}" | sed -e "s/++GOARCH++/${goarch}/g")"
      else
        return 11
      fi
      ;;
  esac

  # Template rendering:GOARM
  case $url in
    *++GOARM++*)
      if __libdl_GOARM >/dev/null; then
        goarm="$(__libdl_GOARM)"
        url="$(printf "%s" "${url}" | sed -e "s/++GOARM++/${gorm}/g")"
      else
        return 11
      fi
      ;;
  esac

  # Template rendering:ARCH
  case $url in
    *%ARCH%*)
      uname_m="$(uname -m)"
      url="$(printf "%s" "${url}" | sed -e "s/++GOOS++/${goos}/g")"
      ;;
  esac

  # Template rendering:OS
  case $url in
    *%OS%*)
      uname_s="$(uname -s)"
      url="${url//%OS%/${uname_s}}"
      ;;
  esac

  printf "%s" "${url}"
}

# Main download file handler.
# This will be called recursively if checksum and gpg keys are remote.
# URLs supports placeholders for GOOS, GOARCH, GOARM, uname -m and uname -r
# Include +GOOS+ +GOARCH+ +GOARM+ in your URL string to replace with GOOS and GOARCH values
download_file()
{
  local remote_url local_file

  local checksum_enable="0"
  local checksum

  local gpg_enable="0"
  local gpg_signature

  local gpg_custom_keyring="0"
  local gpg_key

  local force="0"

  local github_token_enable="0"
  local github_token

  local version_override="0"
  local version

  if [ "$#" -lt 4 ]; then
    return 3
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
        checksum="${1}"
        checksum_enable=1
        ;;
      --singature)
        shift
        gpg_key="${1}"
        gpg_enable=1
        ;;
      --gpg-key)
        shift
        gpg_key="${1}"
        gpg_custom_keyring=1
        ;;
      --force)
        shift
        force=1
        ;;
      --github-token)
        shift
        github_token="${1}"
        ;;
      --version)
        version_override=1
        shift
        version="${1}"
        ;;
      *) return 12 ;;
    esac
    shift
  done

  log_trace "File URL               :" "${remote_url}"
  log_trace "Local File             :" "${local_file}"

  if [ "$checksum_enable" -eq 1 ]; then
    log_trace "Checksum verification  : Enabled"
  else
    log_trace "Checksum verification  : Disabled"
  fi

  if [ "$gpg_enable" -eq 1 ]; then
    log_trace "Signature verification : Enabled"
  else
    log_trace "Signature verification : Disabled"
  fi

  if [ "${gpg_custom_keyring}" -eq 1 ]; then
    log_trace "GPG signing key        : ${gpg_custom_keyring}"
  else
    log_trace "Using default keyring"
  fi

  if [ "${version_override}" ]; then
    if [ "${version_override}" = "latest" ] || [ "${version_override}" = "auto" ]; then
      log_trace "Enable latest version detection via GitHub"
    fi
  fi

  # url basic validity checks
  if [ -z "${url}" ]; then
    return 4
  else
    case ${url} in
      https://* | http://*) ;;
      *)
        log_error "URL MUST start with http:// or https://"
        return 4
        ;;
    esac
  fi

  # destination path check
  if [ -z ${local_file} ] || [ ! -w "$(dirname "${local_file}")" ]; then
    log_error
    return 31
  fi

}
