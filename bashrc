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
        echo disabled | sudo tee "$dev_path/power/wakeup" > /dev/null
    fi

    if [ -f "$dev_path/power/level" ]; then
        echo on | sudo tee "$dev_path/power/level" > /dev/null
    elif [ -f "$dev_path/power/control" ]; then
        echo on | sudo tee "$dev_path/power/control" > /dev/null
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
        echo disabled | sudo tee "$dev_path/power/wakeup" > /dev/null
    fi

    if [ -f "$dev_path/power/level" ]; then
        echo suspend | sudo tee "$dev_path/power/level" > /dev/null
    elif [ -f "$dev_path/power/control" ]; then
        echo suspend | sudo tee "$dev_path/power/control" > /dev/null
    fi

    echo "$dev_upper is now OFF."
}
