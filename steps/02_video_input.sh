#!/bin/bash
# steps/02_video_input.sh
# Step 02: Graphics Drivers (Mesa/Vulkan) & Input Layer (Libinput)

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
log_step "Step 02: Video & Input Subsystems"

# 1. Input Drivers (Libinput)
# Wayland compositors rely heavily on libinput for mouse, keyboard, and touchpad events.
# - libinput-bin/tools: Essential for debugging input events (libinput debug-events).
INPUT_PACKAGES=(
    "libinput-bin"
    "libinput-tools"
    "xwayland"  # Crucial for running legacy X11 apps on Labwc
)

log_info "Installing Input & Legacy X11 Support..."
for pkg in "${INPUT_PACKAGES[@]}"; do
    if ! is_installed "$pkg"; then
        apt-get install -y -q "$pkg"
    fi
done

# 2. Graphics Drivers (Mesa Stack)
# We install a broad set of Mesa drivers to support Intel, AMD, and Virtual Machines (VirtIO).
# - libgl1-mesa-dri: The core Direct Rendering Infrastructure.
# - mesa-vulkan-drivers: Vulkan support (essential for modern UI rendering).
# - mesa-utils: Contains 'glxinfo' and checks.
# - libegl1: The interface between rendering APIs and the native window system.
GRAPHICS_PACKAGES=(
    "libgl1-mesa-dri"
    "libglx-mesa0"
    "libegl1-mesa"
    "mesa-vulkan-drivers"
    "mesa-utils"
    "vulkan-tools"
    "drm-info"
)

log_info "Installing Mesa (OpenGL/Vulkan) Drivers..."
for pkg in "${GRAPHICS_PACKAGES[@]}"; do
    if ! is_installed "$pkg"; then
        log_info "Installing $pkg..."
        apt-get install -y -q "$pkg"
    else
        log_success "$pkg is present."
    fi
done

# 3. Hardware Acceleration (VA-API)
# Enables GPU video decoding (saves battery/CPU on laptops).
# We install drivers for both Intel and AMD/Generic.
VAAPI_PACKAGES=(
    "mesa-va-drivers"
    "libva-drm2"
    "libva-utils"
)

# Optional: Check for Intel hardware to hint about non-free drivers
if lspci | grep -i "Intel" | grep -i "VGA" > /dev/null; then
    log_info "Intel GPU detected. Adding 'intel-media-va-driver'..."
    VAAPI_PACKAGES+=("intel-media-va-driver")
fi

log_info "Installing Hardware Video Acceleration..."
for pkg in "${VAAPI_PACKAGES[@]}"; do
    if ! is_installed "$pkg"; then
        apt-get install -y -q "$pkg"
    fi
done

# 4. Hardware Validation
# We verify that the kernel has successfully loaded the Direct Rendering modules.
log_info "Validating Graphics Subsystem..."

if [ -d "/dev/dri" ]; then
    log_success "Graphics card detected (/dev/dri exists)."
    
    # Check for Render nodes (required for Wayland compositors without root)
    if ls /dev/dri/renderD* 1> /dev/null 2>&1; then
        log_success "Render nodes found (Hardware acceleration available)."
    else
        log_warn "No /dev/dri/renderD* nodes found. Software rendering might be used."
    fi
else
    log_error "Directory /dev/dri not found!"
    log_error "The kernel has not loaded graphics drivers."
    log_error "If this is a VM, ensure 3D Acceleration is enabled in the hypervisor."
    # We don't exit 1 here because software rendering might still work, 
    # but it's a severe warning.
fi

log_success "Step 02 complete. Video and Input stack ready."