#!/bin/sh

set -e

[ "$DEBUG" = "1" ] && set -x

TMP_DIR=$(mktemp -d -t k6-installer-XXXXXXXXXX)

cleanup() {
    rm -rf "$TMP_DIR" > /dev/null 2>&1
}

fail() {
    cleanup
    echo "❌ Error: $1" >&2
    exit 1
}

install_k6() {
    USER="grafana"
    PROG="k6"
    GH_API="https://api.github.com/repos/$USER/$PROG/releases"

    INSTALL_DIR="${K6_INSTALL:-$HOME/.k6}"
    BIN_DIR="$INSTALL_DIR/bin"
    K6_EXE="$BIN_DIR/k6"

    mkdir -p "$BIN_DIR"

    for cmd in curl tar unzip; do
        command -v "$cmd" > /dev/null || fail "❗ Required command '$cmd' is not installed."
    done

    if [ -z "$K6_VERSION" ]; then
        K6_VERSION=$(curl -sSL "$GH_API/latest" | grep '"tag_name":' | head -1 | awk -F '"' '{print $4}' | tr -d 'v')
    fi

    if ! curl --silent --fail --head "https://github.com/$USER/$PROG/releases/tag/v$K6_VERSION" > /dev/null; then
        fail "⚠️ k6 version $K6_VERSION does not exist or is unavailable."
    fi

    SYSTEM_K6_PATH=$(command -v k6 || true)

    if [ -n "$SYSTEM_K6_PATH" ] && [ "$SYSTEM_K6_PATH" != "$K6_EXE" ]; then
        echo "🚨 WARNING: k6 is already installed at: $SYSTEM_K6_PATH via a different method."
        echo "   Installing in $BIN_DIR might override or conflict with the existing installation."
    fi

    if [ -x "$K6_EXE" ]; then
        CURRENT_VERSION=$($K6_EXE version 2>/dev/null | awk '{print $2}' | tr -d 'v')

        if [ "$CURRENT_VERSION" = "$K6_VERSION" ]; then
            echo "✅ k6 is already installed at version $CURRENT_VERSION. No update needed."
            cleanup
            exit 0
        fi

        echo "🔄 Updating k6 from $CURRENT_VERSION to $K6_VERSION..."
    else
        echo "🚀 Installing k6 version $K6_VERSION..."
    fi

    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l) ARCH="arm" ;;
        *) fail "❌ Unsupported architecture: $ARCH" ;;
    esac

    case "${OS}_${ARCH}" in
        "darwin_amd64") FILE="k6-v${K6_VERSION}-macos-amd64.zip" ;;
        "darwin_arm64") FILE="k6-v${K6_VERSION}-macos-arm64.zip" ;;
        "linux_amd64") FILE="k6-v${K6_VERSION}-linux-amd64.tar.gz" ;;
        "linux_arm64") FILE="k6-v${K6_VERSION}-linux-arm64.tar.gz" ;;
        *) fail "❌ No asset available for platform ${OS}-${ARCH}" ;;
    esac

    K6_URL="https://github.com/$USER/$PROG/releases/download/v${K6_VERSION}/${FILE}"

    echo "⬇️ Downloading: $K6_URL"

    curl --fail --location --progress-bar --output "$TMP_DIR/$FILE" "$K6_URL"

    if echo "$FILE" | grep -q ".tar.gz"; then
        tar -xzf "$TMP_DIR/$FILE" -C "$TMP_DIR"
    elif echo "$FILE" | grep -q ".zip"; then
        unzip -q "$TMP_DIR/$FILE" -d "$TMP_DIR"
    fi

    TMP_BIN=$(find "$TMP_DIR" -type f -name "k6" | head -n 1)
    [ ! -f "$TMP_BIN" ] && fail "❌ Could not locate k6 binary after extraction."

    mv "$TMP_BIN" "$K6_EXE"
    chmod +x "$K6_EXE"

    echo "✅ Successfully installed k6 v$K6_VERSION at $K6_EXE"

    cleanup

    echo ""
    echo "📌 To use k6, add it to your PATH by running:"
    echo ""
    echo "   🔹 **For Bash:**"
    echo "     echo 'export PATH=\"$HOME/.k6/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
    echo ""
    echo "   🔹 **For Zsh:**"
    echo "     echo 'export PATH=\"$HOME/.k6/bin:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
    echo ""
    echo "✨ Run 'k6 --help' to get started."
    echo "📖 Learn more: https://grafana.com/docs/k6/latest/"
}

install_k6
