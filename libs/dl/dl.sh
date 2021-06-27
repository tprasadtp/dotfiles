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
# automatically updated and all changes between markers wil be ignored.

# convert `uname -m` to GOARCH and output
# By default function will try to map current uname -m to GOARCH.
# You can optionally pass it as an argument (useful in remote mounted filesystems)
# If cannot convert will return code is 1
libdl_get_GOARCH()
{
  local arch
  arch="${1:-$(uname -m)}"
  case $arch in
    x86_64)
      echo "amd64"
      return 0
      ;;
    x86)
      echo "386"
      return 0
      ;;
    i686)
      echo "386"
      return 0
      ;;
    i386)
      echo "386"
      return 0
      ;;
    aarch64)
      echo "arm64"
      return 0
      ;;
    armv5*)
      echo "armv5"
      return 0
      ;;
    armv6*)
      echo "armv6"
      return 0
      ;;
    armv7*)
      echo "armv7"
      return 0
      ;;
  esac
  # We failed to map architectures to GOARCH
  return 1
}

# Maps os name to GOOS
# By default function will try to map current uname -s to GOARCH.
# You can optionally pass it as an argument (useful in remote mounted mounted filesystems)
# Returns 0 and echos GOOS if supported OS was detected
# otherwise returns 1 and nothing
libdl_get_GOOS()
{
  local os
  os="${1:-$(uname -s)}"
  case "$os" in
    Linux)
      echo "linux"
      return 0
      ;;
    Darwin)
      echo "darwin"
      return 0
      ;;
    CYGWIN_NT* | Windows_NT | MSYS_NT* | MINGW*)
      echo "windows"
      return 0
      ;;
    FreeBSD)
      echo "freebsd"
      return 0
      ;;
  esac
  return 1
}

# ERRORS
__libdl_print_error()
{
  case ${1} in
    # No Errors
    0) ;;

    # Dependency errors
    # Just logging library
    2)
      echo "[ERROR ] Dependency Error."
      echo "[ERROR ] This script requires logger library from https://github.com/tprasadtp/shlibs/logger"
      echo "[ERROR ] Please source it before using dl library."
      ;;

    11)
      log_error "Internal Error."
      log_error "Please report this error to https://github.com/tprasadtp/shlibs"
      log_error "Please include Outputs of following commands in your error reports"
      log_error "1. uname -m"
      log_error "2. uname -r"
      log_error "3. curl --version"
      log_error "4. wget --version"
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
          log_error "sha256sum is provided by package coreutils or openssl. Install one of them via package manager."
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
    # Checksum Errors
    30) log_error "URL specified was invalid or empty" ;;
    31) log_error "Destination specified was invalid or empty" ;;
    32) log_error "Checksum verification was enabled but checksum file, checksum file URL or checksum was not defined or is invalid" ;;

    # GPG Errors
    40) log_error "GPG signature verification was enabled but GPG ID/ Key file or key file URL was not specified" ;;

    # Path errors
    50) log_error "Temp dir is not writable or tempdir creation failed" ;;
    51) log_error "Destination file/directory is not writable" ;;
    52) log_error "Destination directory directory does not exist" ;;

    # Download Errors
    61) log_error "checksum verification was enabled via remote file, but failed to fetch it after multiple attempts!" ;;
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
    if curl --version 2>&1 >/dev/null; then
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
    if wget --version 2>&1 >/dev/null; then
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
    if gpgv --version 2>&1 >/dev/null; then
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
    if gpg --version 2>&1 >/dev/null; then
      return 0
    else
      return 2
    fi
  fi
  return 1
}
