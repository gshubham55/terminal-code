#!/bin/bash
#
# Terminal Mac IDE Mac Installer
# Downloads and installs Terminal Mac IDE from GitHub releases
#
# Usage:
#   ./install-mac.sh              # Install latest stable version
#   ./install-mac.sh --beta       # Install beta version
#   ./install-mac.sh --force      # Force install (no prompts, kills running app)
#   ./install-mac.sh --beta -f    # Beta version, force mode
#
# Or run directly:
#   curl -fsSL https://raw.githubusercontent.com/gshubham55/terminal-code/main/install-mac.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/gshubham55/terminal-code/main/install-mac.sh | bash -s -- --beta
#

set -e

REPO="gshubham55/terminal-code"
FORCE_MODE=false
BETA_MODE=false

# Hardcoded versions
STABLE_VERSION="v1.0.23-beta"
BETA_VERSION="v1.0.24-beta"

# Parse arguments
for arg in "$@"; do
    case $arg in
        -f|--force)
            FORCE_MODE=true
            ;;
        --beta)
            BETA_MODE=true
            ;;
    esac
done

APP_NAME="Terminal Mac IDE"
INSTALL_DIR="/Applications"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    ARCH_SUFFIX="arm64"
    info "Detected Apple Silicon (arm64)"
elif [ "$ARCH" = "x86_64" ]; then
    ARCH_SUFFIX="x64"
    info "Detected Intel (x64)"
else
    error "Unsupported architecture: $ARCH"
fi

# Select version based on channel
if [ "$BETA_MODE" = true ]; then
    VERSION="$BETA_VERSION"
    info "Using beta channel"
else
    VERSION="$STABLE_VERSION"
    info "Using stable channel"
fi

# Remove 'v' prefix if present for filename matching
VERSION_NUM="${VERSION#v}"

info "Installing Terminal Mac IDE $VERSION for $ARCH_SUFFIX..."

# DMG filename pattern
DMG_NAME="Terminal.Mac.IDE-${VERSION_NUM}-${ARCH_SUFFIX}.dmg"
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/$DMG_NAME"

# Create temp directory
TEMP_DIR=$(mktemp -d)
DMG_PATH="$TEMP_DIR/$DMG_NAME"
MOUNT_POINT=""

cleanup() {
    info "Cleaning up..."
    if [ -n "$MOUNT_POINT" ] && [ -d "$MOUNT_POINT" ]; then
        hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true
    fi
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Download DMG
info "Downloading $DMG_NAME..."
if ! curl -fSL "$DOWNLOAD_URL" -o "$DMG_PATH"; then
    error "Failed to download $DOWNLOAD_URL

Make sure the release exists: https://github.com/$REPO/releases/tag/$VERSION"
fi

# Verify download
if [ ! -f "$DMG_PATH" ]; then
    error "Download failed - file not found"
fi

DMG_SIZE=$(ls -lh "$DMG_PATH" | awk '{print $5}')
info "Downloaded $DMG_SIZE"

# Mount DMG
info "Mounting DMG..."
MOUNT_OUTPUT=$(hdiutil attach "$DMG_PATH" -nobrowse 2>&1)
if [ $? -ne 0 ]; then
    echo "$MOUNT_OUTPUT"
    error "Failed to attach DMG"
fi

# Parse mount point
MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | grep "/Volumes" | sed 's/.*\(\/Volumes\/.*\)/\1/' | head -1)
if [ -z "$MOUNT_POINT" ]; then
    MOUNT_POINT="/Volumes/$APP_NAME"
fi

sleep 1

if [ ! -d "$MOUNT_POINT" ]; then
    warn "Expected mount point not found: $MOUNT_POINT"
    warn "Available volumes:"
    ls -la /Volumes/
    error "Failed to mount DMG"
fi

info "Mounted at $MOUNT_POINT"

# Check if app is running
if pgrep -x "$APP_NAME" > /dev/null 2>&1; then
    if [ "$FORCE_MODE" = true ]; then
        info "Force mode: Closing Terminal Mac IDE..."
        pkill -x "$APP_NAME" 2>/dev/null || true
        sleep 2
    else
        warn "Terminal Mac IDE is currently running."
        read -p "Close it and continue? (y/N) " -n 1 -r </dev/tty
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Closing Terminal Mac IDE..."
            pkill -x "$APP_NAME" 2>/dev/null || true
            sleep 2
        else
            error "Please close Terminal Mac IDE and try again."
        fi
    fi
fi

# Remove existing installation
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    OLD_VERSION=$(defaults read "$INSTALL_DIR/$APP_NAME.app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "unknown")
    warn "Replacing existing installation (v$OLD_VERSION)..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

# Copy app
info "Installing to $INSTALL_DIR..."
cp -R "$MOUNT_POINT/$APP_NAME.app" "$INSTALL_DIR/"

# Unmount
info "Unmounting DMG..."
hdiutil detach "$MOUNT_POINT" -quiet

# Remove quarantine and ad-hoc sign (fixes dyld cache issue for embedded binaries)
info "Removing quarantine attribute..."
xattr -cr "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

# Sign resource binaries individually first (--deep doesn't reach extraResources)
info "Ad-hoc signing embedded binaries..."
RESOURCES="$INSTALL_DIR/$APP_NAME.app/Contents/Resources"
for bin in "$RESOURCES/deno" "$RESOURCES/cloudide-backend"; do
    if [ -f "$bin" ]; then
        codesign --force --sign - "$bin" 2>/dev/null && info "  Signed $(basename "$bin")"
    fi
done

info "Ad-hoc signing app..."
codesign --force --deep --sign - "$INSTALL_DIR/$APP_NAME.app"

# Verify installation
CHANNEL="stable"
if [ "$BETA_MODE" = true ]; then
    CHANNEL="beta"
fi

if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Terminal Mac IDE $VERSION ($CHANNEL) installed successfully!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "To launch: open '$INSTALL_DIR/$APP_NAME.app'"
    echo "Or find it in Applications folder"
    echo ""
else
    error "Installation verification failed"
fi
