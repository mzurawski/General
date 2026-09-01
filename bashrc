# USB Power Control Functions

find_gin_usb_device() {
    local sys_usb_dir="${SYS_USB_DIR:-/sys/bus/usb/devices}"
    if [ ! -d "$sys_usb_dir" ]; then
        return 1
    fi
    for dev_path in "$sys_usb_dir"/*; do
        if [ -d "$dev_path" ]; then
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

_sysfs_write() {
    local val="$1"
    local target="$2"
    if [ -w "$target" ]; then
        echo "$val" > "$target" 2>/dev/null
    else
        echo "$val" | sudo tee "$target" > /dev/null
    fi
}

usb-on() {
    local dev_path
    dev_path=$(find_gin_usb_device)
    if [ -z "$dev_path" ]; then
        echo "GiN mbH USB device not found." >&2
        return 1
    fi
    local dev_name
    dev_name=$(basename "$dev_path")
    local dev_upper
    dev_upper=$(echo "$dev_name" | tr '[:lower:]' '[:upper:]')

    if [ -f "$dev_path/power/wakeup" ]; then
        _sysfs_write disabled "$dev_path/power/wakeup"
    fi

    if [ -f "$dev_path/power/level" ]; then
        _sysfs_write on "$dev_path/power/level"
    elif [ -f "$dev_path/power/control" ]; then
        _sysfs_write on "$dev_path/power/control"
    fi

    echo "$dev_upper is now ON."
}

usb-off() {
    local dev_path
    dev_path=$(find_gin_usb_device)
    if [ -z "$dev_path" ]; then
        echo "GiN mbH USB device not found." >&2
        return 1
    fi
    local dev_name
    dev_name=$(basename "$dev_path")
    local dev_upper
    dev_upper=$(echo "$dev_name" | tr '[:lower:]' '[:upper:]')

    if [ -f "$dev_path/power/wakeup" ]; then
        _sysfs_write disabled "$dev_path/power/wakeup"
    fi

    if [ -f "$dev_path/power/level" ]; then
        _sysfs_write suspend "$dev_path/power/level"
    elif [ -f "$dev_path/power/control" ]; then
        _sysfs_write suspend "$dev_path/power/control"
    fi

    echo "$dev_upper is now OFF."
}
