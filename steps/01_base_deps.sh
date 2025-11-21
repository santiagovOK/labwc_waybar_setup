#!/bin/bash
# steps/01_base_deps.sh
# Step 01: Base Session, Hardware, Audio & Connectivity
# Updated: Asks user confirmation before disabling Swap.

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
log_step "Step 01: Base Session, Audio & Hardware"

# 1. Session Management & Hardware Abstraction
SESSION_PACKAGES=(
    "dbus-user-session"
    "libpam-systemd"
    "policykit-1"
    "seatd"
    "libseat1"
)

# 2. Audio & Bluetooth Stack (Pipewire)
AUDIO_PACKAGES=(
    "firmware-realtek"
    "pipewire-audio"
    "pipewire-pulse"
    "wireplumber"
    "libspa-0.2-bluetooth"
)

# 3. User Utilities
UTIL_PACKAGES=(
    "xdg-user-dirs"
    "bash-completion"
    "htop"
    "radeontop" # For AMD GPU
    "locales"
)

ALL_PACKAGES=("${SESSION_PACKAGES[@]}" "${AUDIO_PACKAGES[@]}" "${UTIL_PACKAGES[@]}")

log_info "Installing Base Dependencies..."
for pkg in "${ALL_PACKAGES[@]}"; do
    if ! is_installed "$pkg"; then
        log_info "Installing $pkg..."
        apt-get install -y -q "$pkg"
    else
        log_success "$pkg is already present."
    fi
done

# 4. Configure User Groups
log_info "Configuring user groups..."
CURRENT_USER=$(logname 2>/dev/null || echo $SUDO_USER)

if [[ -n "$CURRENT_USER" ]]; then
    # Video
    if ! groups "$CURRENT_USER" | grep -q "\bvideo\b"; then
        usermod -aG video "$CURRENT_USER"
        log_success "Added $CURRENT_USER to 'video'."
    fi
    # Input
    if ! groups "$CURRENT_USER" | grep -q "\binput\b"; then
        usermod -aG input "$CURRENT_USER"
        log_success "Added $CURRENT_USER to 'input'."
    fi
    # Bluetooth
    if getent group bluetooth >/dev/null; then
        if ! groups "$CURRENT_USER" | grep -q "\bbluetooth\b"; then
            usermod -aG bluetooth "$CURRENT_USER"
            log_success "Added $CURRENT_USER to 'bluetooth'."
        fi
    fi
    
    log_info "Updating XDG user directories..."
    sudo -u "$CURRENT_USER" xdg-user-dirs-update
else
    log_warn "Could not detect sudo user. Skipping group modifications."
fi

# 5. Disable Swap (Interactive)
# We ask the user because low-RAM systems might crash without swap.
if grep -q "swap" /proc/swaps; then
    echo ""
    log_warn "Active Swap detected."
    log_info "Disabling swap can improve SSD life but requires sufficient RAM."
    
    # Interactive Prompt
    # -r: prevents backslash interpretation
    # -p: prompt text
    read -r -p "Do you want to disable Swap permanently? [y/N] " response
    
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Disabling active Swap..."
        swapoff -a
        
        if grep -q "^[^#].*swap" /etc/fstab; then
            log_info "Commenting out swap entry in /etc/fstab..."
            sed -i '/swap/s/^/#/' /etc/fstab
        fi
        log_success "Swap has been disabled."
    else
        log_info "Skipping Swap disable (User opted to keep it)."
    fi
else
    log_success "No active swap detected."
fi

# 6. Service Management
log_info "Configuring System Services..."

if systemctl list-unit-files | grep -q seatd.service; then
    systemctl enable --now seatd
    log_success "Seatd enabled."
fi

if systemctl list-unit-files | grep -q wireplumber.service; then
    systemctl --global enable wireplumber.service
    log_success "Wireplumber enabled globally."
fi

# 7. Final Notices
log_step "IMPORTANT AUDIO SETUP"
log_warn "To finalize Pipewire, reboot and run as USER:"
log_warn "  systemctl --user --now enable wireplumber pipewire pipewire-pulse"

log_success "Step 01 complete."