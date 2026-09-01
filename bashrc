# USB Power Control Functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usb-on() {
    if [ -x "$SCRIPT_DIR/usb-on.sh" ]; then
        "$SCRIPT_DIR/usb-on.sh"
    elif command -v usb-on.sh >/dev/null 2>&1; then
        usb-on.sh
    else
        echo "usb-on.sh not found." >&2
        return 1
    fi
}

usb-off() {
    if [ -x "$SCRIPT_DIR/usb-off.sh" ]; then
        "$SCRIPT_DIR/usb-off.sh"
    elif command -v usb-off.sh >/dev/null 2>&1; then
        usb-off.sh
    else
        echo "usb-off.sh not found." >&2
        return 1
    fi
}
