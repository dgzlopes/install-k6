#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# 0. Parse optional arguments (e.g., "0.54.0" or "v0.54.0" and "--no-update-check").
###############################################################################
DISABLE_UPDATES_CHECK=false
user_version=""

for arg in "$@"; do
  case $arg in
    --no-update-check)
      DISABLE_UPDATES_CHECK=true
      shift
      ;;
    *)
      user_version="$arg"
      shift
      ;;
  esac
done

if [[ -n "$user_version" ]]; then
  if [[ ! "$user_version" =~ ^v ]]; then
    user_version="v$user_version"
  fi
  export K6_VERSION="$user_version"
fi

###############################################################################
# 1. Define color variables and helper functions (inspired by Bun’s approach).
###############################################################################

# Defaults if not running in a TTY
Color_Off=''
Red=''
Green=''
Dim=''
Bold_White=''
Bold_Green=''
Yellow=''

if [[ -t 1 ]]; then
  # Reset
  Color_Off='\033[0m'    # Text Reset

  # Regular Colors
  Red='\033[0;31m'       # Red
  Green='\033[0;32m'     # Green
  Yellow='\033[0;33m'    # Yellow
  Dim='\033[0;2m'        # Dim/Faint

  # Bold
  Bold_White='\033[1m'   # Bold White
  Bold_Green='\033[1;32m' # Bold Green
fi

error() {
  echo -e "${Red}error${Color_Off}: $*" >&2
}

fail() {
  error "$@"
  exit 1
}

warn() {
  echo -e "${Yellow}warning${Color_Off}: $*"
}

info() {
  echo -e "${Dim}$*${Color_Off}"
}

info_bold() {
  echo -e "${Bold_White}$*${Color_Off}"
}

success() {
  echo -e "${Green}$*${Color_Off}"
}

###############################################################################
# 2. Create a temporary directory and define cleanup.
###############################################################################

TMP_DIR="$(mktemp -d -t k6-installer-XXXXXXXXXX)"

cleanup() {
  rm -rf "$TMP_DIR" > /dev/null 2>&1
}
trap cleanup EXIT

###############################################################################
# 3. Main install function.
###############################################################################

install_k6() {
  local USER="grafana"
  local PROG="k6"
  # Remove GH_API and references to GitHub

  local INSTALL_DIR="${K6_INSTALL:-$HOME/.k6}"
  local BIN_DIR="$INSTALL_DIR/bin"
  local K6_EXE="$BIN_DIR/k6"
  local WRAPPER_URL="https://install-k6.com/k6-wrapper.sh"
  local WRAPPER_EXE="$BIN_DIR/k6"

  mkdir -p "$BIN_DIR"

  # Check required commands
  for cmd in curl tar unzip; do
    command -v "$cmd" &>/dev/null || fail "Required command '$cmd' is not installed."
  done

  # Determine the K6 version if not provided
  if [[ -z "${K6_VERSION:-}" ]]; then
    info "Fetching the latest k6 version..."
    K6_VERSION="$(curl -sSL https://install-k6.com/latest-version.txt | awk '{print $1}')"
  fi

  # Validate the custom version if provided
  if [[ -n "$user_version" ]]; then
    if ! curl --silent --fail --head "https://github.com/$USER/$PROG/releases/tag/$K6_VERSION" > /dev/null; then
      fail "k6 version $K6_VERSION does not exist or is unavailable."
    fi
  fi

  # Check if k6 is already installed in the system
  local SYSTEM_K6_PATH
  SYSTEM_K6_PATH="$(command -v k6 || true)"
  if [[ -n "$SYSTEM_K6_PATH" && "$SYSTEM_K6_PATH" != "$K6_EXE" ]]; then
    warn "k6 is already installed at: $SYSTEM_K6_PATH
Installing in $BIN_DIR might override or conflict with the existing installation."
  fi

  # Determine if this is an update
  local UPDATE_MODE=false
  if [[ -x "$K6_EXE" ]]; then
    local CURRENT_VERSION
    CURRENT_VERSION="$("$K6_EXE" version 2>/dev/null | awk '/k6-cli/ {print $2}')"

    if [[ "$CURRENT_VERSION" == "$K6_VERSION" ]]; then
      success "k6 is already at version $CURRENT_VERSION. No update needed."
      exit 0
    fi

    info_bold "Updating k6 from $CURRENT_VERSION to $K6_VERSION..."
    UPDATE_MODE=true
  else
    info_bold "Installing k6 version $K6_VERSION..."
  fi

  # Determine OS and ARCH
  local OS
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  local ARCH
  ARCH="$(uname -m)"

  case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    arm64) ARCH="arm64" ;;
    *) fail "Unsupported architecture: $ARCH" ;;
  esac

  # Map OS and ARCH to official k6 binaries
  local FILE
  case "${OS}_${ARCH}" in
    darwin_amd64)  FILE="k6-${K6_VERSION}-macos-amd64.zip" ;;
    darwin_arm64)  FILE="k6-${K6_VERSION}-macos-arm64.zip" ;;
    linux_amd64)   FILE="k6-${K6_VERSION}-linux-amd64.tar.gz" ;;
    linux_arm64)   FILE="k6-${K6_VERSION}-linux-arm64.tar.gz" ;;
    *) fail "No binary asset available for ${OS}-${ARCH}." ;;
  esac

  local K6_URL="https://github.com/$USER/$PROG/releases/download/${K6_VERSION}/${FILE}"

  info "Downloading binary: $K6_URL"
  curl --fail --location --progress-bar --output "$TMP_DIR/$FILE" "$K6_URL"

  # Extract
  if [[ "$FILE" =~ \.tar\.gz$ ]]; then
    tar -xzf "$TMP_DIR/$FILE" -C "$TMP_DIR"
  elif [[ "$FILE" =~ \.zip$ ]]; then
    unzip -qo "$TMP_DIR/$FILE" -d "$TMP_DIR"
  fi

  # Move the binary into place
  local TMP_BIN
  TMP_BIN="$(find "$TMP_DIR" -type f -name "k6" | head -n 1)"
  [[ ! -f "$TMP_BIN" ]] && fail "Could not locate k6 binary after extraction."

  if [[ "$DISABLE_UPDATES_CHECK" == true ]]; then
    mv "$TMP_BIN" "$K6_EXE"
  else
    mv "$TMP_BIN" "$BIN_DIR/k6-cli"
    chmod +x "$BIN_DIR/k6-cli"

    # Download the wrapper script, rename to k6, and make it executable
    info "Downloading wrapper: $WRAPPER_URL"
    curl --fail --location --progress-bar --output "$WRAPPER_EXE" "$WRAPPER_URL"
    chmod +x "$WRAPPER_EXE"
  fi

  if [[ "$UPDATE_MODE" == true ]]; then
    success "Successfully updated k6 to version $K6_VERSION."
  else
    success "Successfully installed k6 v$K6_VERSION at $K6_EXE"
  fi
}

###############################################################################
# 4. Automatically append k6 to PATH in shell config, or show manual instructions.
###############################################################################

add_to_path_in_shell_config() {
  # If k6 is already in PATH, no need to do anything.
  if command -v k6 >/dev/null 2>&1; then
    info "k6 is already on your PATH. Run 'k6 --help' to get started!"
    return
  fi

  local shell_name
  shell_name="$(basename "${SHELL:-}")"
  local install_dir="${K6_INSTALL:-$HOME/.k6}"
  local bin_dir="$install_dir/bin"

  # We'll add these lines for bash/zsh
  local lines="# k6 config\nexport K6_INSTALL=\"$install_dir\"\nexport PATH=\"\$K6_INSTALL/bin:\$PATH\"\n"
  local wrote_file=false

  case "$shell_name" in
    bash)
      # Attempt .bashrc, .bash_profile, etc.
      local bash_configs=("$HOME/.bashrc" "$HOME/.bash_profile")
      if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
        bash_configs+=("$XDG_CONFIG_HOME/bashrc" "$XDG_CONFIG_HOME/.bashrc" "$XDG_CONFIG_HOME/.bash_profile")
      fi

      for f in "${bash_configs[@]}"; do
        if [[ -w "$f" ]]; then
          {
            echo ""
            echo -e "$lines"
          } >> "$f"

          success "Added k6 to PATH in '$f'. Run 'source $f' or open a new shell to use k6."
          wrote_file=true
          break
        fi
      done
      ;;
    zsh)
      local zshrc="$HOME/.zshrc"
      if [[ -w "$zshrc" ]]; then
        {
          echo ""
          echo -e "$lines"
        } >> "$zshrc"

        success "Added k6 to PATH in '$zshrc'. Run 'exec zsh' or open a new shell to use k6."
        wrote_file=true
      fi
      ;;
    fish)
      # fish syntax is different, so let's define fish lines:
      local fish_config="$HOME/.config/fish/config.fish"
      local fish_lines="# k6 config (fish)\nset --export K6_INSTALL \"$install_dir\"\nset --export PATH \$K6_INSTALL/bin \$PATH\n"

      if [[ -w "$fish_config" ]]; then
        {
          echo ""
          echo -e "$fish_lines"
        } >> "$fish_config"

        success "Added k6 to PATH in '$fish_config'. Run 'source $fish_config' or open a new shell to use k6."
        wrote_file=true
      fi
      ;;
    *)
      warn "Unknown or unsupported shell ($shell_name)."
      ;;
  esac

  # If we didn't manage to write to a config file, show manual instructions
  if [[ "$wrote_file" == false ]]; then
    echo
    warn "Could not automatically update PATH. Add these lines to your shell’s config file manually:"
    echo -e "$lines"
  fi
}

###############################################################################
# 5. Run the installer, then show path instructions (auto-append or fallback).
###############################################################################

install_k6
add_to_path_in_shell_config

echo
info_bold "Run 'k6 --help' to confirm your installation!"