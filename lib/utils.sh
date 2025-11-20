#!/bin/bash
# lib/utils.sh
# Core library for Debian Labwc Setup
# Provides: Logging, Error Handling, and Validation Checks

# ==============================================================================
# 1. CONSTANTS & COLORS
# ==============================================================================
readonly LOG_FILE="logs/install_$(date +%Y-%m-%d).log"

# ANSI Color Codes for visual hierarchy
readonly R='\033[0;31m'   # Red (Error)
readonly G='\033[0;32m'   # Green (Success)
readonly Y='\033[0;33m'   # Yellow (Warning)
readonly B='\033[0;34m'   # Blue (Info)
readonly C='\033[0;36m'   # Cyan (Step Title)
readonly N='\033[0m'      # No Color (Reset)

# Ensure log directory exists
mkdir -p logs

# ==============================================================================
# 2. LOGGING FUNCTIONS
# ==============================================================================

# Log to both console and file
_log() {
    local type="$1"
    local color="$2"
    local message="$3"
    local timestamp
    timestamp=$(date +"%H:%M:%S")

    # Print to Console with Color
    echo -e "${color}[${timestamp}] [${type}] ${message}${N}" >&2
    
    # Append to Log File (No Color)
    echo "[${timestamp}] [${type}] ${message}" >> "$LOG_FILE"
}

log_info() {
    _log "INFO" "$B" "$1"
}

log_success() {
    _log "OK" "$G" "$1"
}

log_warn() {
    _log "WARN" "$Y" "$1"
}

log_error() {
    _log "ERROR" "$R" "$1"
}

log_step() {
    echo ""
    _log "STEP" "$C" "------------------------------------------------"
    _log "STEP" "$C" "$1"
    _log "STEP" "$C" "------------------------------------------------"
}

# ==============================================================================
# 3. ERROR HANDLING (The Trap)
# ==============================================================================

# Function triggered on any error (non-zero exit code)
error_handler() {
    local line_no=$1
    local exit_code=$2
    local last_command=$3
    
    log_error "Critical failure detected!"
    log_error "Failed command: $last_command"
    log_error "Line: $line_no | Exit Code: $exit_code"
    log_error "See $LOG_FILE for full details."
    
    # Optional: Add cleanup logic here (unmounting, deleting temp files)
    
    exit "$exit_code"
}

# ==============================================================================
# 4. VALIDATION FUNCTIONS
# ==============================================================================

# Check if user is root
assert_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (sudo)."
        exit 1
    fi
    log_success "Root privileges confirmed."
}

# Check internet connectivity
check_internet() {
    log_info "Checking internet connectivity..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log_success "Internet connection active."
    else
        log_error "No internet connection. Cannot download packages."
        exit 1
    fi
}

# Check Debian version
assert_debian_trixie() {
    log_info "Verifying OS version..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "debian" ]]; then
            log_success "Detected Debian System."
            # Warn if not Trixie, but allow proceeding with a warning
            if [[ "$VERSION_CODENAME" != "trixie" ]]; then
                log_warn "Detected $VERSION_CODENAME (Expected: trixie). Setup may vary."
            else
                log_success "Detected Debian Trixie."
            fi
        else
            log_error "This script is for Debian only. Detected: $ID"
            exit 1
        fi
    else
        log_error "Cannot determine OS. /etc/os-release missing."
        exit 1
    fi
}

# Check if a specific package is installed
is_installed() {
    dpkg -l "$1" &> /dev/null
}