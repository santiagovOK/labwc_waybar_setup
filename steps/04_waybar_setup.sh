#!/bin/bash
# steps/04_waybar_setup.sh
# Step 04: Status Bar (Waybar), Fonts & Tray Applications

# ==============================================================================
# BOOTSTRAP
# ==============================================================================
LIB_PATH="lib/utils.sh"
if [[ ! -f "$LIB_PATH" && -f "../$LIB_PATH" ]]; then cd ..; fi
if [[ ! -f "$LIB_PATH" ]]; then echo "CRITICAL: Lib not found"; exit 1; fi
source "$LIB_PATH"
trap 'error_handler ${LINENO} $? "$BASH_COMMAND"' ERR INT TERM

# ==============================================================================
# LOGIC
# ==============================================================================
log_step "Step 04: Installing Waybar & Assets"

# 1. The Status Bar
# Waybar: The standard bar for wlroots compositors.
log_info "Installing Waybar..."
if ! is_installed "waybar"; then
    apt-get install -y -q waybar
else
    log_success "Waybar is already installed."
fi

# 2. Fonts & Assets (CRITICAL)
# - fonts-font-awesome: Required for standard icons (battery, wifi, etc.).
# - fonts-noto-color-emoji: Ensures emojis render correctly.
# - fonts-recommended: General good-to-have fonts for UI.
FONT_PACKAGES=(
    "fonts-font-awesome"
    "fonts-noto-color-emoji"
    "fonts-dejavu"
)

log_info "Installing Fonts (Icons & Glyphs)..."
for pkg in "${FONT_PACKAGES[@]}"; do
    if ! is_installed "$pkg"; then
        log_info "Installing $pkg..."
        apt-get install -y -q "$pkg"
    else
        log_success "$pkg is already installed."
    fi
done

# 3. System Tray & GUI Utilities
# Waybar modules usually click-through to these GUIs:
# - pavucontrol: The standard GTK Volume Mixer (Pipewire/Pulse).
# - blueman: Bluetooth manager (provides tray icon).
# - network-manager-gnome: Provides 'nm-applet' (Network tray icon).
TRAY_APPS=(
    "pavucontrol"
    "blueman"
    "network-manager-gnome"
)

log_info "Installing Tray Applications (Audio/Net/BT GUIs)..."
for pkg in "${TRAY_APPS[@]}"; do
    if ! is_installed "$pkg"; then
        log_info "Installing $pkg..."
        apt-get install -y -q "$pkg"
    else
        log_success "$pkg is present."
    fi
done

# 4. Weather & JSON Utilities (Optional but common for Waybar)
# - jq: Command-line JSON processor (used by custom Waybar scripts for weather/updates).
if ! is_installed "jq"; then
    log_info "Installing jq (JSON processor for custom modules)..."
    apt-get install -y -q jq
fi

# 5. Configuration Prep
# We verify the configuration directory exists so permissions are correct
# before we try to link files in Step 05.
CURRENT_USER=$(logname 2>/dev/null || echo $SUDO_USER)
USER_HOME=$(eval echo "~$CURRENT_USER")

if [[ -n "$CURRENT_USER" ]]; then
    CONFIG_DIR="$USER_HOME/.config/waybar"
    if [[ ! -d "$CONFIG_DIR" ]]; then
        log_info "Creating config directory: $CONFIG_DIR"
        mkdir -p "$CONFIG_DIR"
        chown -R "$CURRENT_USER":"$CURRENT_USER" "$USER_HOME/.config"
    fi
fi

# 6. Validation
log_info "Verifying installations..."
REQUIRED_BINS=("waybar" "pavucontrol" "blueman-manager" "nm-applet")

for bin in "${REQUIRED_BINS[@]}"; do
    if command -v "$bin" >/dev/null 2>&1; then
        log_success "Binary '$bin' detected."
    else
        log_warn "Binary '$bin' missing. Tray icons may fail."
    fi
done

log_success "Step 04 complete. Waybar and UI assets ready."