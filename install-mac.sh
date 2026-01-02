#!/bin/bash
#
# Terminal IDE Mac Installer
# Downloads and installs Terminal IDE from GitHub releases
#
# Usage:
#   ./install-mac.sh              # Install latest version
#   ./install-mac.sh v1.0.1       # Install specific version
#   ./install-mac.sh --force      # Force install (no prompts, kills running app)
#   ./install-mac.sh v1.0.1 -f    # Specific version, force mode
#
# Or run directly:
#   curl -fsSL https://raw.githubusercontent.com/gshubham55/terminal-code/main/terminal-app/scripts/install-mac.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/gshubham55/terminal-code/main/terminal-app/scripts/install-mac.sh | bash -s v1.0.1
#

set -e

REPO="gshubham55/terminal-code"
FORCE_MODE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        -f|--force)
            FORCE_MODE=true
            ;;
    esac
done
APP_NAME="Terminal IDE"
INSTALL_DIR="/Applications"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Get version (from argument or latest) - skip flags
VERSION=""
for arg in "$@"; do
    case $arg in
        -f|--force) ;;  # Skip flags
        *) VERSION="$arg"; break ;;
    esac
done

if [ -z "$VERSION" ]; then
    info "Fetching latest release..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$VERSION" ]; then
        error "Could not determine latest version. Please specify a version: ./install-mac.sh v1.0.1"
    fi
fi

# Remove 'v' prefix if present for filename matching
VERSION_NUM="${VERSION#v}"

info "Installing Terminal IDE $VERSION for $ARCH_SUFFIX..."

# DMG filename pattern (uses dots, not spaces):
# - ARM64: Terminal.IDE-{version}-arm64.dmg
# - x64: Terminal.IDE-{version}.dmg (no suffix)
if [ "$ARCH_SUFFIX" = "arm64" ]; then
    DMG_NAME="Terminal.IDE-${VERSION_NUM}-arm64.dmg"
else
    DMG_NAME="Terminal.IDE-${VERSION_NUM}.dmg"
fi
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/$DMG_NAME"

# Create temp directory
TEMP_DIR=$(mktemp -d)
DMG_PATH="$TEMP_DIR/$DMG_NAME"

cleanup() {
    info "Cleaning up..."
    # Unmount if still mounted
    if [ -d "/Volumes/$APP_NAME" ]; then
        hdiutil detach "/Volumes/$APP_NAME" -quiet 2>/dev/null || true
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
MOUNT_POINT=$(hdiutil attach "$DMG_PATH" -nobrowse -quiet | grep "/Volumes" | awk '{print $3}')
if [ -z "$MOUNT_POINT" ]; then
    # Try alternate parsing
    MOUNT_POINT="/Volumes/$APP_NAME"
fi

if [ ! -d "$MOUNT_POINT" ]; then
    error "Failed to mount DMG"
fi

info "Mounted at $MOUNT_POINT"

# Check if app is running
if pgrep -f "$APP_NAME" > /dev/null 2>&1; then
    if [ "$FORCE_MODE" = true ]; then
        info "Force mode: Closing Terminal IDE..."
        pkill -f "$APP_NAME" 2>/dev/null || true
        sleep 2
    else
        warn "Terminal IDE is currently running."
        read -p "Close it and continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Closing Terminal IDE..."
            pkill -f "$APP_NAME" 2>/dev/null || true
            sleep 2
        else
            error "Please close Terminal IDE and try again."
        fi
    fi
fi

# Remove existing installation
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    # Get current version if possible
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

# Remove quarantine and sign
info "Removing quarantine attribute..."
xattr -cr "$INSTALL_DIR/$APP_NAME.app"

info "Ad-hoc signing app..."
codesign --force --deep --sign - "$INSTALL_DIR/$APP_NAME.app"

# Verify installation
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Terminal IDE $VERSION installed successfully!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "To launch: open '$INSTALL_DIR/$APP_NAME.app'"
    echo "Or find it in Applications folder"
    echo ""
else
    error "Installation verification failed"
fi
