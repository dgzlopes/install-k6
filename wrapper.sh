#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Wrapper Script.
# This file is called "k6" and should be placed in $K6_INSTALL/bin,
# while the real binary is located at $K6_INSTALL/bin/runtime/k6.
###############################################################################

# 0. Basic color/logging
Color_Off=''
Red=''
Green=''
Yellow=''
Blue=''
Dim=''

if [[ -t 1 ]]; then
  Color_Off='\033[0m'
  Red='\033[0;31m'
  Green='\033[0;32m'
  Yellow='\033[0;33m'
  Blue='\033[0;34m'
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
REAL_BINARY="$K6_INSTALL/bin/runtime/k6"
INSTALLER_URL="https://install-k6.com/please.sh"
FIRST_RUN_MARKER="$K6_INSTALL/.first_run"

###############################################################################
# 2. Ensure the real k6 binary exists
###############################################################################

if [[ ! -f "$REAL_BINARY" ]]; then
  fail "The k6 binary ($REAL_BINARY) was not found.
Please reinstall k6, e.g.:
  curl -fsSL $INSTALLER_URL | bash"
fi

###############################################################################
# 3. Run k6 first
###############################################################################

"$REAL_BINARY" "$@"
k6_exit_code=$?

###############################################################################
# 4. Check for updates (after k6 completes)
###############################################################################

installed_version="$("$REAL_BINARY" version | awk '{print $2}')"
latest_version="$(curl -sSL https://install-k6.com/latest-version.txt | awk '{print $1}')"

if [[ -n "$latest_version" && "$latest_version" != "$installed_version" ]]; then
  warn "A newer version of k6 ($latest_version) is available (you have $installed_version)."
  info "You can update by running: curl -fsSL $INSTALLER_URL | bash"
fi

###############################################################################
# 5. Display a one-minute tutorial for new users (only on first run)
###############################################################################

if [[ ! -f "$FIRST_RUN_MARKER" ]]; then
  echo ""---------------------------------------------------------------------------""
  echo -e "${Green}Running k6 for the first time?! Welcome!${Color_Off}"
  echo -e "${Dim}Here are two quick ways for you to get started:${Color_Off}"
  echo ""
  echo -e "   ${Yellow}[A]${Color_Off} Explore our *awesome* guides:"
  echo -e "       - ${Blue}https://grafana.com/docs/k6/latest/get-started/${Color_Off}"
  echo ""
  echo -e "   ${Yellow}[B]${Color_Off} Jump straight in and get your hands dirty:"
  echo -e "       - Create a new test with: ${Yellow}k6 new${Color_Off}"
  echo -e "       - Run it with: ${Yellow}k6 run script.js${Color_Off}"
  echo ""
  echo -e "That's it! Enjoy your testing!${Color_Off}"
  echo ""---------------------------------------------------------------------------""
  echo -e "${Yellow}Psst... Did you know Grafana Cloud k6 exists? Result Analysis, Cloud Execution, and more.${Color_Off}"
  echo -e "Get started with our *actually useful* free tier: ${Blue}https://grafana.com/products/cloud/k6/${Color_Off}"
  echo -e "${Dim}Btw: Yes, this welcome note pops up only once. We promise!${Color_Off}"
  echo ""
  touch "$FIRST_RUN_MARKER"
fi


###############################################################################
# 6. Exit with the original k6 exit code
###############################################################################

exit "$k6_exit_code"
