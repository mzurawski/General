#!/usr/bin/env bash
# usb-off.sh - Dynamically locate, unbind driver, and suspend power for "GiN mbH" USB devices

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

# 1. Locate the GiN mbH USB device sysfs directory
dev_path=$(find_gin_usb_device)
if [ -z "$dev_path" ]; then
    echo "GiN mbH USB device not found." >&2
    exit 1
fi

dev_name=$(basename "$dev_path")
dev_upper=$(echo "$dev_name" | tr '[:lower:]' '[:upper:]')
sys_drivers_dir="${SYS_DRIVERS_DIR:-/sys/bus/usb/drivers/usb}"

# 2. Disable wakeup if supported by the device sysfs interface
if [ -f "$dev_path/power/wakeup" ]; then
    _sysfs_write disabled "$dev_path/power/wakeup"
fi

# 3. Turn off / suspend power to the USB device
# Modern kernels use /sys/bus/usb/devices/.../power/control (values: 'auto' to suspend, or 'on').
# Older kernels used /sys/bus/usb/devices/.../power/level (values: 'suspend' or 'on').
if [ -f "$dev_path/power/control" ]; then
    _sysfs_write auto "$dev_path/power/control"
elif [ -f "$dev_path/power/level" ]; then
    _sysfs_write suspend "$dev_path/power/level"
fi

# 4. Unbind driver to safely disconnect and turn off USB device functionality on Ubuntu Linux
if [ -f "$sys_drivers_dir/unbind" ]; then
    _sysfs_write "$dev_name" "$sys_drivers_dir/unbind"
fi

echo "$dev_upper is now OFF."
