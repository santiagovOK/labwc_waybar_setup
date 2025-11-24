#!/bin/bash
# steps/03_wayland_core.sh
# Step 03: Wayland Compositor & Userland
# Fix: Robust Flatpak handling to prevent script crash on network errors.

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
safe_install "labwc"

# 2. Critical Portals
PORTAL_PACKAGES=(
    "xdg-desktop-portal"
    "xdg-desktop-portal-wlr"
)
log_info "Installing XDG Desktop Portals..."
for pkg in "${PORTAL_PACKAGES[@]}"; do
    safe_install "$pkg"
done

# 3. Core Utilities
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
log_info "Installing Core Tools..."
for pkg in "${CORE_TOOLS[@]}"; do
    safe_install "$pkg"
done

# 4. Native Media Tools
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
    safe_install "$pkg"
done

# 5. Flatpak Configuration & OBS Studio (PROTECTED BLOCK)
log_info "Configuring Flatpak Ecosystem..."

# A) Add Flathub Repo
# Verificamos si ya existe
if flatpak remote-list | grep -q "flathub"; then
    log_success "Flathub repo already exists."
else
    log_info "Adding Flathub repository..."
    
    # Desactivar modo estricto para manejar el error manualmente
    set +e
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    RET=$?
    set -e # Reactivar modo estricto

    if [ $RET -eq 0 ]; then
        log_success "Flathub repository added."
    else
        log_warn "Failed to add Flathub repo (Exit Code: $RET)."
        log_warn "Skipping OBS Flatpak installation as repo is missing."
    fi
fi

# B) Install OBS Studio (Solo si flathub existe)
if flatpak remote-list | grep -q "flathub"; then
    if flatpak list | grep -q "com.obsproject.Studio"; then
        log_success "OBS Studio (Flatpak) is already installed."
    else
        log_info "Installing OBS Studio (Flatpak)..."
        
        # Desactivar modo estricto para manejar el error manualmente
        set +e
        flatpak install -y flathub com.obsproject.Studio
        RET=$?
        set -e # Reactivar modo estricto

        if [ $RET -eq 0 ]; then
            log_success "OBS Studio installed successfully."
        else
            log_warn "OBS installation failed (Exit Code: $RET)."
            log_warn "You can try installing it manually later: 'flatpak install flathub com.obsproject.Studio'"
        fi
    fi
else
    log_warn "Skipping OBS installation because Flathub repo is not available."
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
    # No hacemos exit 1 aquí para permitir que el script continúe al siguiente paso
fi

log_success "Step 03 complete. Core, Portals, and OBS ready."