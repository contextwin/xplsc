#!/bin/bash

# XFCE4 Power & Lock Settings Checker
# Author: Assistant
# Version: 1.0
# Description: Check and display XFCE4 power management and screen lock settings
# License: MIT

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${CYAN}===============================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${CYAN}===============================================${NC}"
}

print_section() {
    echo -e "\n${BLUE}--- $1 ---${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${PURPLE}ℹ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get xfconf value safely
get_xfconf_value() {
    local channel="$1"
    local property="$2"
    xfconf-query -c "$channel" -p "$property" 2>/dev/null || echo "N/A"
}

# Function to analyze setting
analyze_setting() {
    local setting_name="$1"
    local value="$2"
    local expected="$3"
    local description="$4"
    
    printf "%-40s: %-10s" "$setting_name" "$value"
    
    if [[ "$value" == "$expected" ]]; then
        echo -e " ${GREEN}✓${NC} $description"
    elif [[ "$value" == "N/A" ]]; then
        echo -e " ${YELLOW}?${NC} Not set"
    else
        echo -e " ${RED}✗${NC} Should be $expected - $description"
    fi
}

# Main function
main() {
    print_header "XFCE4 Power & Lock Settings Checker"
    
    # Check if running XFCE4
    if [[ "$XDG_CURRENT_DESKTOP" != *"XFCE"* ]] && [[ "$DESKTOP_SESSION" != *"xfce"* ]]; then
        print_warning "Not running XFCE4 desktop environment"
        print_info "Current desktop: $XDG_CURRENT_DESKTOP"
    fi
    
    # Check required commands
    print_section "System Requirements"
    if ! command_exists xfconf-query; then
        print_error "xfconf-query not found. Please install xfce4-utils"
        exit 1
    else
        print_success "xfconf-query found"
    fi
    
    if ! command_exists xset; then
        print_warning "xset not found. X11 settings cannot be checked"
    else
        print_success "xset found"
    fi
    
    # XFCE4 Power Manager Settings
    print_section "XFCE4 Power Manager Settings"
    
    # Get all power manager settings
    blank_ac=$(get_xfconf_value "xfce4-power-manager" "/xfce4-power-manager/blank-on-ac")
    blank_battery=$(get_xfconf_value "xfce4-power-manager" "/xfce4-power-manager/blank-on-battery")
    dpms_enabled=$(get_xfconf_value "xfce4-power-manager" "/xfce4-power-manager/dpms-enabled")
    dpms_ac_off=$(get_xfconf_value "xfce4-power-manager" "/xfce4-power-manager/dpms-on-ac-off")
    dpms_ac_sleep=$(get_xfconf_value "xfce4-power-manager" "/xfce4-power-manager/dpms-on-ac-sleep")
    dpms_battery_off=$(get_xfconf_value "xfce4-power-manager" "/xfce4-power-manager/dpms-on-battery-off")
    dpms_battery_sleep=$(get_xfconf_value "xfce4-power-manager" "/xfce4-power-manager/dpms-on-battery-sleep")
    sleep_ac=$(get_xfconf_value "xfce4-power-manager" "/xfce4-power-manager/inactivity-sleep-mode-on-ac")
    sleep_battery=$(get_xfconf_value "xfce4-power-manager" "/xfce4-power-manager/inactivity-sleep-mode-on-battery")
    lock_suspend=$(get_xfconf_value "xfce4-power-manager" "/xfce4-power-manager/lock-screen-suspend-hibernate")
    
    analyze_setting "Blank screen on AC" "$blank_ac" "0" "Screen blanking disabled"
    analyze_setting "Blank screen on battery" "$blank_battery" "0" "Screen blanking disabled"
    analyze_setting "DPMS enabled" "$dpms_enabled" "false" "Display power management disabled"
    analyze_setting "DPMS AC off timeout" "$dpms_ac_off" "0" "No auto-off on AC power"
    analyze_setting "DPMS AC sleep timeout" "$dpms_ac_sleep" "0" "No auto-sleep on AC power"
    analyze_setting "DPMS battery off timeout" "$dpms_battery_off" "0" "No auto-off on battery"
    analyze_setting "DPMS battery sleep timeout" "$dpms_battery_sleep" "0" "No auto-sleep on battery"
    analyze_setting "Sleep mode on AC" "$sleep_ac" "0" "No auto-sleep on AC power"
    analyze_setting "Sleep mode on battery" "$sleep_battery" "0" "No auto-sleep on battery"
    analyze_setting "Lock on suspend/hibernate" "$lock_suspend" "false" "No lock on suspend"
    
    # XFCE4 Session Settings
    print_section "XFCE4 Session Settings"
    
    screensaver_type=$(get_xfconf_value "xfce4-session" "/startup/screensaver/type")
    lock_screen=$(get_xfconf_value "xfce4-session" "/shutdown/LockScreen")
    lock_command=$(get_xfconf_value "xfce4-session" "/general/LockCommand")
    
    analyze_setting "Screensaver type" "$screensaver_type" "" "No screensaver enabled"
    analyze_setting "Lock screen on shutdown" "$lock_screen" "false" "No lock on shutdown"
    analyze_setting "Lock command" "$lock_command" "" "No lock command set"
    
    # XFCE4 Screensaver Settings
    print_section "XFCE4 Screensaver Settings"
    
    sleep_activation=$(get_xfconf_value "xfce4-screensaver" "/lock/sleep-activation")
    analyze_setting "Lock on sleep activation" "$sleep_activation" "false" "No lock on sleep"
    
    # X11 Settings
    if command_exists xset; then
        print_section "X11 Settings"
        
        # Get xset information
        xset_output=$(xset q 2>/dev/null || echo "")
        
        if [[ -n "$xset_output" ]]; then
            # Parse screen saver settings
            screen_saver_info=$(echo "$xset_output" | grep -A2 "Screen Saver" || echo "")
            if [[ -n "$screen_saver_info" ]]; then
                timeout=$(echo "$screen_saver_info" | grep "timeout" | awk '{print $2}' | head -1)
                analyze_setting "X11 screensaver timeout" "$timeout" "0" "Screensaver disabled"
            fi
            
            # Parse DPMS settings
            dpms_info=$(echo "$xset_output" | grep -A3 "DPMS" || echo "")
            if [[ -n "$dpms_info" ]]; then
                dpms_status=$(echo "$dpms_info" | grep "DPMS is" | awk '{print $3}' || echo "Unknown")
                analyze_setting "X11 DPMS status" "$dpms_status" "Disabled" "Display power management disabled"
            fi
        fi
    fi
    
    # Process Information
    print_section "Running Processes"
    
    # Check for screensaver processes
    screensaver_processes=$(ps aux | grep -E "(xscreensaver|light-locker|xfce4-screensaver)" | grep -v grep | wc -l)
    if [[ "$screensaver_processes" -eq 0 ]]; then
        print_success "No screensaver processes running"
    else
        print_warning "Screensaver processes detected:"
        ps aux | grep -E "(xscreensaver|light-locker|xfce4-screensaver)" | grep -v grep || true
    fi
    
    # System Information
    print_section "System Information"
    
    # Check systemd inhibitors
    if command_exists systemd-inhibit; then
        print_info "Active systemd inhibitors:"
        systemd-inhibit --list 2>/dev/null | head -10 || print_warning "Cannot get inhibitor list"
    fi
    
    # Check autostart applications
    print_info "Autostart applications related to screen/power:"
    autostart_dir="$HOME/.config/autostart"
    if [[ -d "$autostart_dir" ]]; then
        find "$autostart_dir" -name "*.desktop" -exec grep -l -i "screen\|power\|lock" {} \; 2>/dev/null || print_info "No screen/power related autostart apps"
    fi
    
    # Summary
    print_section "Summary"
    
    # Count problematic settings
    problem_count=0
    
    # Check critical settings
    critical_settings=(
        "$sleep_ac:0"
        "$sleep_battery:0"
        "$dpms_enabled:false"
        "$lock_screen:false"
    )
    
    for setting in "${critical_settings[@]}"; do
        value="${setting%%:*}"
        expected="${setting##*:}"
        if [[ "$value" != "$expected" ]] && [[ "$value" != "N/A" ]]; then
            ((problem_count++))
        fi
    done
    
    if [[ "$problem_count" -eq 0 ]]; then
        print_success "All critical settings are properly configured!"
        print_info "Your system should not auto-sleep or auto-lock"
    else
        print_warning "Found $problem_count problematic setting(s)"
        print_info "Review the settings above and adjust as needed"
    fi
    
    print_header "Check Complete"
    echo -e "${CYAN}Report generated on: $(date)${NC}"
    echo -e "${CYAN}Hostname: $(hostname)${NC}"
    echo -e "${CYAN}User: $(whoami)${NC}"
}

# Help function
show_help() {
    echo "XFCE4 Power & Lock Settings Checker"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --version  Show version information"
    echo ""
    echo "This script checks XFCE4 power management and screen lock settings"
    echo "to help troubleshoot unwanted auto-sleep and auto-lock behavior."
}

# Version function
show_version() {
    echo "XFCE4 Power & Lock Settings Checker v1.0"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--version)
        show_version
        exit 0
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
