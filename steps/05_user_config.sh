#!/bin/bash
# steps/05_user_config.sh
# Step 05: User Configuration & Dotfiles Linking
# - Symlinks configs from ./config/ to ~/.config/
# - Injects environment variables and aliases into .bashrc

# ==============================================================================
# BOOTSTRAP
# ==============================================================================
LIB_PATH="lib/utils.sh"
if [[ ! -f "$LIB_PATH" && -f "../$LIB_PATH" ]]; then cd ..; fi
if [[ ! -f "$LIB_PATH" ]]; then echo "CRITICAL: Lib not found"; exit 1; fi
source "$LIB_PATH"
trap 'error_handler ${LINENO} $? "$BASH_COMMAND"' ERR INT TERM

# ==============================================================================
# SETUP & VALIDATION
# ==============================================================================
log_step "Step 05: Applying User Configurations"

# Detect actual user (sudo wrapper hides this usually)
CURRENT_USER=$(logname 2>/dev/null || echo "$SUDO_USER")
if [[ -z "$CURRENT_USER" || "$CURRENT_USER" == "root" ]]; then
    log_error "Cannot determine target non-root user. Do not run as pure root login."
    exit 1
fi

USER_HOME=$(eval echo "~$CURRENT_USER")
PROJECT_CONFIG_DIR="$(pwd)/config"

log_info "Target User: $CURRENT_USER"
log_info "User Home: $USER_HOME"

# Helper: Link a directory or file safely
# Usage: install_config "source_folder_name" "target_folder_name"
install_config() {
    local src_name="$1"
    local dest_path="$2"
    local full_src_path="$PROJECT_CONFIG_DIR/$src_name"
    local full_dest_path="$USER_HOME/.config/$dest_path"

    if [[ ! -e "$full_src_path" ]]; then
        log_warn "Source config '$src_name' not found in project. Skipping."
        return
    fi

    log_info "Linking $src_name -> .config/$dest_path"

    # Ensure parent directory exists
    mkdir -p "$(dirname "$full_dest_path")"

    # Backup if it exists and is not already a symlink to our source
    if [[ -e "$full_dest_path" && ! -L "$full_dest_path" ]]; then
        log_info "Backing up existing config to ${full_dest_path}.bak"
        mv "$full_dest_path" "${full_dest_path}.bak"
    fi

    # Create the symlink
    # -s: symbolic, -f: force (overwrite link)
    ln -sf "$full_src_path" "$full_dest_path"
    
    # Fix ownership of the link itself (since we are running as root)
    chown -h "$CURRENT_USER":"$CURRENT_USER" "$full_dest_path"
}

# ==============================================================================
# 1. DOTFILES LINKING
# ==============================================================================
log_info "Deploying dotfiles..."

# Ensure project config dir exists
if [[ ! -d "$PROJECT_CONFIG_DIR" ]]; then
    log_warn "No 'config' directory found in project root. Creating skeleton..."
    mkdir -p config/{labwc,waybar,foot}
fi

# Link specific modules
# Structure: config/labwc -> ~/.config/labwc
install_config "labwc" "labwc"
install_config "waybar" "waybar"
install_config "foot" "foot"

# Fix permissions recursively on .config to be safe
chown -R "$CURRENT_USER":"$CURRENT_USER" "$USER_HOME/.config"

# ==============================================================================
# 2. BASHRC INJECTION (Env Vars & Aliases)
# ==============================================================================
log_info "Updating .bashrc with Wayland settings..."

# Change as needed for your setup

BASHRC="$USER_HOME/.bashrc"
MARKER="# === DEBIAN-LABWC-SETUP-START ==="

# We use a HEREDOC variable to store the block we want to insert.
# Note: We escape $ variables that belong to the user's shell (like $TERM).
read -r -d '' BASH_BLOCK << EOM
$MARKER
# Added by install.sh on $(date +%Y-%m-%d)

# 1. Environment Variables
export MOZ_ENABLE_WAYLAND=1
export COLORTERM=truecolor

# Fix for terminals not reporting truecolor correctly
case "\$TERM" in
    *-truecolor) ;;
    *-256color)  ;;
    *)           export TERM=xterm-256color ;;
esac

# 2. Aliases
# VS Code on Wayland , not Xwayland
alias code='code --ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations'

# Display Management (WLR-RANDR) - Change as needed
alias secondarydisplay='wlr-randr --output HDMI-A-1 --on --mode 1920x1080@30.00 --output DP-1 --off'
alias secondarydisplay60='wlr-randr --output HDMI-A-1 --on --mode 1920x1080@60.00 --output DP-1 --off'
alias onedisplay='wlr-randr --output DP-1 --on --mode 1920x1080@143.854996 --adaptive-sync enabled --output HDMI-A-1 --off'

# Screenshot (Copy to clipboard and edit) - setup on rc.xml
alias shot='grim -g "\$(slurp)" - | swappy -f -'

# === DEBIAN-LABWC-SETUP-END ===
EOM

# Check if we already added this block to avoid duplicates
if grep -Fq "$MARKER" "$BASHRC"; then
    log_success ".bashrc already contains the configuration block. Skipping."
else
    # Append to .bashrc
    echo "$BASH_BLOCK" >> "$BASHRC"
    log_success "Configuration appended to .bashrc"
fi

# ==============================================================================
# 3. REMINDERS (Manual Actions)
# ==============================================================================

# Change as needed for your setup

log_step "Manual Configuration Reminders"

log_info "1. IntelliJ/Java Apps:"
echo "   Edit 'Help -> Edit Custom VM Options' and add:"
echo "   -Dawt.toolkit.name=WLToolkit"

log_info "2. Browsers (Brave/Chrome):"
echo "   Go to brave://flags and set 'Ozone Platform' to 'Wayland' or 'Auto'."

log_info "3. Tor Browser:"
echo "   Add 'export MOZ_ENABLE_WAYLAND=1' to start-tor-browser script."

log_success "Step 05 complete. User configuration finished."