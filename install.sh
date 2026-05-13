#!/bin/bash
#
# Neovim URL Handler Installer
# Registers nvim:// protocol handler for xdg-open
#
# Usage: ./install.sh [--uninstall]
#

set -e

SCRIPT_NAME="nvim-url-handler"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"
HANDLER_SCRIPT="$BIN_DIR/$SCRIPT_NAME"
DESKTOP_FILE="$APPS_DIR/$SCRIPT_NAME.desktop"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

check_dependencies() {
    info "Checking dependencies..."
    
    if ! command -v nvim &> /dev/null; then
        error "nvim is not installed. Please install Neovim first."
    fi
    
    if ! command -v python3 &> /dev/null; then
        error "python3 is not installed. Required for URL decoding."
    fi
    
    if ! command -v xdg-mime &> /dev/null; then
        error "xdg-mime is not installed. Please install xdg-utils."
    fi
    
    info "All dependencies found."
}

install_handler() {
    info "Installing Neovim URL handler..."
    
    # Create directories if they don't exist
    mkdir -p "$BIN_DIR"
    mkdir -p "$APPS_DIR"
    
    # Create the URL handler script
    info "Creating handler script at $HANDLER_SCRIPT"
    cat > "$HANDLER_SCRIPT" << 'HANDLER_EOF'
#!/bin/bash
# Parse nvim:// URLs and open in nvim
# Format: nvim://open?url=file:///path/to/file&line=N&column=N

url="$1"

if [[ -z "$url" ]]; then
    echo "Usage: nvim-url-handler 'nvim://open?url=file:///path&line=N&column=N'"
    exit 1
fi

# Extract file path (decode URL encoding)
file=$(echo "$url" | sed -n 's/.*url=file:\/\/\([^&]*\).*/\1/p' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))")

# Extract line number
line=$(echo "$url" | sed -n 's/.*line=\([0-9]*\).*/\1/p')

# Extract column number  
col=$(echo "$url" | sed -n 's/.*column=\([0-9]*\).*/\1/p')

if [[ -n "$file" ]]; then
    if [[ -n "$line" && -n "$col" ]]; then
        exec nvim "+call cursor($line,$col)" "$file"
    elif [[ -n "$line" ]]; then
        exec nvim "+$line" "$file"
    else
        exec nvim "$file"
    fi
else
    echo "Could not parse URL: $url"
    exit 1
fi
HANDLER_EOF

    chmod +x "$HANDLER_SCRIPT"
    info "Handler script created and made executable."
    
    # Create the .desktop file
    info "Creating desktop entry at $DESKTOP_FILE"
    cat > "$DESKTOP_FILE" << DESKTOP_EOF
[Desktop Entry]
Name=Neovim URL Handler
GenericName=Text Editor
Comment=Open nvim:// URLs in Neovim
TryExec=nvim
Exec=$HANDLER_SCRIPT %u
Terminal=true
Type=Application
Icon=nvim
Categories=Utility;TextEditor;
NoDisplay=true
MimeType=x-scheme-handler/nvim;
DESKTOP_EOF

    info "Desktop entry created."
    
    # Update desktop database
    info "Updating desktop database..."
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$APPS_DIR" 2>/dev/null || true
    fi
    
    # Register as default handler
    info "Registering as default handler for nvim:// protocol..."
    xdg-mime default "$SCRIPT_NAME.desktop" x-scheme-handler/nvim
    
    # Verify registration
    registered=$(xdg-mime query default x-scheme-handler/nvim)
    if [[ "$registered" == "$SCRIPT_NAME.desktop" ]]; then
        info "Successfully registered as default handler."
    else
        warn "Registration may have failed. Current handler: $registered"
    fi
    
    echo ""
    info "Installation complete!"
    echo ""
    echo "Test with:"
    echo "  xdg-open 'nvim://open?url=file:///etc/hosts&line=1&column=1'"
    echo ""
    echo "Or test the handler directly:"
    echo "  $HANDLER_SCRIPT 'nvim://open?url=file:///etc/hosts&line=1&column=1'"
    echo ""
}

uninstall_handler() {
    info "Uninstalling Neovim URL handler..."
    
    # Remove handler script
    if [[ -f "$HANDLER_SCRIPT" ]]; then
        rm -f "$HANDLER_SCRIPT"
        info "Removed handler script."
    else
        warn "Handler script not found at $HANDLER_SCRIPT"
    fi
    
    # Remove desktop file
    if [[ -f "$DESKTOP_FILE" ]]; then
        rm -f "$DESKTOP_FILE"
        info "Removed desktop entry."
    else
        warn "Desktop entry not found at $DESKTOP_FILE"
    fi
    
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$APPS_DIR" 2>/dev/null || true
    fi
    
    # Remove from mimeapps.list
    MIMEAPPS="$HOME/.config/mimeapps.list"
    if [[ -f "$MIMEAPPS" ]]; then
        sed -i '/x-scheme-handler\/nvim/d' "$MIMEAPPS"
        info "Removed handler from mimeapps.list"
    fi
    
    echo ""
    info "Uninstallation complete!"
}

show_help() {
    echo "Neovim URL Handler Installer"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --install     Install the nvim:// URL handler (default)"
    echo "  --uninstall   Remove the nvim:// URL handler"
    echo "  --help        Show this help message"
    echo ""
    echo "This script registers a handler for nvim:// URLs, allowing you to"
    echo "click links like nvim://open?url=file:///path&line=N to open files"
    echo "in Neovim at a specific line and column."
}

# Main
case "${1:-}" in
    --uninstall)
        uninstall_handler
        ;;
    --help|-h)
        show_help
        ;;
    --install|"")
        check_dependencies
        install_handler
        ;;
    *)
        error "Unknown option: $1. Use --help for usage."
        ;;
esac
