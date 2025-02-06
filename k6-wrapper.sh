#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# k6 Wrapper Script. 
# This file is called "k6" and should be placed in $K6_INSTALL/bin, while the
# real binary is named "k6-cli".
###############################################################################

# 0. Basic color/logging
Color_Off=''
Red=''
Green=''
Yellow=''
Dim=''

if [[ -t 1 ]]; then
  Color_Off='\033[0m'
  Red='\033[0;31m'
  Green='\033[0;32m'
  Yellow='\033[0;33m'
  Dim='\033[0;2m'
fi

error() {
  echo -e "${Red}error${Color_Off}: $*" >&2
}

warn() {
  echo -e "${Yellow}warning${Color_Off}: $*"
}

fail() {
  error "$@"
  exit 1
}

info() {
  echo -e "${Dim}$*${Color_Off}"
}

###############################################################################
# 1. Environment & Paths
###############################################################################

K6_INSTALL="${K6_INSTALL:-$HOME/.k6}"
BIN_DIR="$K6_INSTALL/bin"

REAL_K6="$BIN_DIR/k6-cli"                        # The actual k6 binary
VERSION_FILE="$K6_INSTALL/.k6_installed_version" # Stores installed k6 version
INSTALLER_URL="https://install-k6.com/please.sh" # Your main installer script

###############################################################################
# 2. Ensure the real k6 binary exists
###############################################################################

if [[ ! -f "$REAL_K6" ]]; then
  fail "The real k6 binary ($REAL_K6) was not found.
Please reinstall k6, e.g.:
  curl -fsSL $INSTALLER_URL | bash"
fi

###############################################################################
# 3. Run k6 first
###############################################################################

# Run the real k6 command and capture the exit code
"$REAL_K6" "$@"
k6_exit_code=$?

###############################################################################
# 4. Check for updates (after k6 completes)
###############################################################################

# Get the installed version using k6-cli version command
installed_version="$("$REAL_K6" version | awk '{print $2}')"

# Replace local file read with URL fetch
latest_version="$(curl -sSL https://install-k6.com/latest-version.txt | awk '{print $1}')"

# Compare
if [[ -n "$latest_version" && "$latest_version" != "$installed_version" ]]; then
  warn "A newer version of k6 ($latest_version) is available (you have $installed_version)."
  info "You can update by running: curl -fsSL $INSTALLER_URL | bash"
fi

# Finally, exit with the original k6 exit code
exit "$k6_exit_code"
