# USB Power Control Functions
# Convenience wrappers/macros in bashrc that execute standalone scripts usb-on.sh and usb-off.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Turn on GiN mbH USB device power
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

# Turn off / suspend GiN mbH USB device power
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
