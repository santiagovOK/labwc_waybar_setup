#!/bin/bash
# steps/00_preflight.sh
# Step 00: System Preparation & Base Dependencies

# ==============================================================================
# BOOTSTRAP (Library Loading)
# ==============================================================================
# We are running from the project root (set by main.sh), so we look for lib/ relative to CWD.
LIB_PATH="lib/utils.sh"

# Fallback: If run directly from steps/ folder, adjust path
if [[ ! -f "$LIB_PATH" && -f "../$LIB_PATH" ]]; then
    cd ..
fi

if [[ ! -f "$LIB_PATH" ]]; then
    echo "CRITICAL ERROR: Cannot find library at $LIB_PATH"
    exit 1
fi

source "$LIB_PATH"

# Initialize Trap for this subprocess
trap 'error_handler ${LINENO} $? "$BASH_COMMAND"' ERR INT TERM

# ==============================================================================
# LOGIC
# ==============================================================================
log_step "Step 00: Preflight Checks & Base Updates"

# 1. Configure Apt for Non-Interactive Mode
# Prevents the script from hanging on "Do you want to keep configuration?" dialogs
export DEBIAN_FRONTEND=noninteractive

# 2. Update Repository Cache
log_info "Updating package lists..."
apt-get update -q

# 3. Upgrade Existing System
# We verify if upgrades are needed to keep logs clean
updates_count=$(apt-get -s upgrade | grep -P '^\d+ upgraded' | cut -d" " -f1)
if [[ "$updates_count" -gt 0 ]]; then
    log_warn "Found $updates_count packages to upgrade. Proceeding..."
    apt-get upgrade -y -q
    log_success "System upgrade complete."
else
    log_success "System is already up to date."
fi

# 4. Install Essential Core Utilities
# These are dependencies for the script itself and general system stability.
# build-essential: needed for compiling drivers/tools if binaries aren't available.
# curl/wget: for downloading config files or assets.
# git: for cloning config repositories.
CORE_PACKAGES=(
    "build-essential"
    "curl"
    "wget"
    "git"
    "unzip"
    "software-properties-common"
)

log_info "Verifying core dependencies: ${CORE_PACKAGES[*]}"

for pkg in "${CORE_PACKAGES[@]}"; do
    if ! is_installed "$pkg"; then
        log_info "Installing $pkg..."
        apt-get install -y -q "$pkg"
    else
        log_success "$pkg is already installed."
    fi
done

# 5. Clean up
log_info "Cleaning up package cache..."
apt-get autoremove -y -q
apt-get clean

log_success "Step 00 complete. System is ready for Wayland components."