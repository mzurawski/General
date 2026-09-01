#!/bin/bash
# usb-on.sh - Dynamically locate, enable USB port power, and re-bind driver for "GiN mbH" USB devices

STATE_FILE="${GIN_USB_STATE_FILE:-/tmp/gin_usb_device}"

# Function: find_gin_usb_device
# Scans /sys/bus/usb/devices/ (or $SYS_USB_DIR if testing) for any connected USB device
# whose manufacturer or product sysfs attribute matches "GiN mbH".
# Returns the device sysfs path (e.g. /sys/bus/usb/devices/2-1) if found.
find_gin_usb_device() {
    local sys_usb_dir="${SYS_USB_DIR:-/sys/bus/usb/devices}"
    if [ ! -d "$sys_usb_dir" ]; then
        return 1
    fi
    for dev_path in "$sys_usb_dir"/*; do
        if [ -d "$dev_path" ]; then
            # Check if manufacturer or product contains "GiN mbH"
            if [ -f "$dev_path/manufacturer" ] && grep -qs "GiN mbH" "$dev_path/manufacturer"; then
                echo "$dev_path"
                return 0
            fi
            if [ -f "$dev_path/product" ] && grep -qs "GiN mbH" "$dev_path/product"; then
                echo "$dev_path"
                return 0
            fi
        fi
    done
    return 1
}

# Function: _sysfs_write <value> <target_file>
# Writes value to target sysfs file. If the file is writable by the current user,
# it writes directly; otherwise it uses sudo tee to elevate privileges.
_sysfs_write() {
    local val="$1"
    local target="$2"
    if [ -w "$target" ]; then
        echo "$val" > "$target" 2>/dev/null
    else
        echo "$val" | sudo tee "$target" > /dev/null
    fi
}

sys_usb_dir="${SYS_USB_DIR:-/sys/bus/usb/devices}"
sys_drivers_dir="${SYS_DRIVERS_DIR:-/sys/bus/usb/drivers/usb}"

# 1. Locate the GiN mbH USB device sysfs directory or read from state file
dev_path=$(find_gin_usb_device)
if [ -n "$dev_path" ]; then
    dev_name=$(basename "$dev_path")
elif [ -f "$STATE_FILE" ]; then
    dev_name=$(cat "$STATE_FILE")
    dev_path="$sys_usb_dir/$dev_name"
else
    echo "GiN mbH USB device not found." >&2
    exit 1
fi

dev_upper=$(echo "$dev_name" | tr '[:lower:]' '[:upper:]')

# 2. Enable physical USB port power if supported by kernel sysfs ($dev_path/disable file: 0 = enabled)
if [ -f "$dev_path/disable" ]; then
    _sysfs_write 0 "$dev_path/disable"
fi

# 3. Disable wakeup if supported by the device sysfs interface
if [ -f "$dev_path/power/wakeup" ]; then
    _sysfs_write disabled "$dev_path/power/wakeup"
fi

# 4. Enable USB power control in sysfs
# Modern kernels use /sys/bus/usb/devices/.../power/control (values: 'on' or 'auto').
# Older kernels used /sys/bus/usb/devices/.../power/level (values: 'on' or 'suspend').
if [ -f "$dev_path/power/control" ]; then
    _sysfs_write on "$dev_path/power/control"
elif [ -f "$dev_path/power/level" ]; then
    _sysfs_write on "$dev_path/power/level"
fi

# 5. Bind driver to re-enable and initialize the USB device in Linux
if [ -f "$sys_drivers_dir/bind" ]; then
    _sysfs_write "$dev_name" "$sys_drivers_dir/bind"
fi

# 6. If uhubctl is available on the system, toggle port power via uhubctl
if command -v uhubctl >/dev/null 2>&1; then
    sudo uhubctl -l "$dev_name" -a on >/dev/null 2>&1 || sudo uhubctl -a on >/dev/null 2>&1 || true
fi

# Clean up state file once device is powered on and re-bound
rm -f "$STATE_FILE" 2>/dev/null || true

echo "$dev_upper is now ON."
