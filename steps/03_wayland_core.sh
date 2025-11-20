#!/bin/bash
# steps/03_wayland_core.sh
# Step 03: Wayland Compositor & Userland (Updated with Flatpak OBS)

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
log_step "Step 03: Wayland Core, Portals & Flatpak Apps"

# 1. Labwc (Compositor)
log_info "Installing Labwc..."
if ! is_installed "labwc"; then
    apt-get install -y -q labwc
else
    log_success "Labwc is already installed."
fi

# 2. Critical Portals (REQUIRED for Screen Sharing)
# - xdg-desktop-portal-wlr: The specific backend for wlroots (Labwc/Sway).
# - xdg-desktop-portal: The frontend that apps (OBS/Firefox) talk to.
PORTAL_PACKAGES=(
    "xdg-desktop-portal"
    "xdg-desktop-portal-wlr"
)

log_info "Installing XDG Desktop Portals (Screen Share Support)..."
for pkg in "${PORTAL_PACKAGES[@]}"; do
    if ! is_installed "$pkg"; then
        apt-get install -y -q "$pkg"
    fi
done

# 3. Core Utilities
# Added 'flatpak' here as a base requirement.
CORE_TOOLS=(
    "foot"
    "fuzzel"
    "swaybg"
    "swaylock"
    "swayidle"
    "wl-clipboard"
    "wlr-randr"
    "x11-utils"
    "flatpak" 
)

log_info "Installing Core Tools & Flatpak..."
for pkg in "${CORE_TOOLS[@]}"; do
    if ! is_installed "$pkg"; then
        apt-get install -y -q "$pkg"
    fi
done

# 4. Media & Screenshot Stack
# Note: OBS is removed from here, handled via Flatpak below.
MEDIA_APPS=(
    "grim"
    "slurp"
    "swappy"
    "atril"
    "swayimg"
    "gnome-calculator"
)

log_info "Installing Native Media Tools..."
for pkg in "${MEDIA_APPS[@]}"; do
    if ! is_installed "$pkg"; then
        apt-get install -y -q "$pkg"
    fi
done

# 5. Flatpak Configuration & OBS Studio
log_info "Configuring Flatpak Ecosystem..."

# Add Flathub Repository
if ! flatpak remote-list | grep -q "flathub"; then
    log_info "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# Install OBS Studio via Flatpak
# com.obsproject.Studio is the official ID
if ! flatpak list | grep -q "com.obsproject.Studio"; then
    log_info "Installing OBS Studio (Flatpak)..."
    flatpak install -y flathub com.obsproject.Studio
else
    log_success "OBS Studio (Flatpak) is already installed."
fi

# 6. Validation
log_info "Verifying critical binaries..."
REQUIRED=("labwc" "swappy" "flatpak")

for bin in "${REQUIRED[@]}"; do
    if command -v "$bin" >/dev/null 2>&1; then
        log_success "Binary '$bin' detected."
    else
        log_warn "Binary '$bin' not found. Check logs."
    fi
done

# Check Portal Service files
if [ -f /usr/share/xdg-desktop-portal/portals/wlr.portal ]; then
    log_success "Portal backend (wlr.portal) detected."
else
    log_error "wlr.portal definition missing! Screen sharing will fail."
    exit 1
fi

log_success "Step 03 complete. Core, Portals, and OBS ready."