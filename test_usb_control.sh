#!/usr/bin/env bash
set -e

sudo() {
    "$@"
}
export -f sudo

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

export SYS_USB_DIR="$TEST_DIR/sys/bus/usb/devices"
mkdir -p "$SYS_USB_DIR"

# Create mock USB device 1 (Other vendor)
mkdir -p "$SYS_USB_DIR/1-1/power"
echo "Generic USB Hub" > "$SYS_USB_DIR/1-1/manufacturer"
echo "enabled" > "$SYS_USB_DIR/1-1/power/wakeup"
echo "auto" > "$SYS_USB_DIR/1-1/power/level"

# Create mock USB device 2 (GiN mbH)
mkdir -p "$SYS_USB_DIR/2-1/power"
echo "GiN mbH" > "$SYS_USB_DIR/2-1/manufacturer"
echo "GiN CAN Bus Interface" > "$SYS_USB_DIR/2-1/product"
echo "enabled" > "$SYS_USB_DIR/2-1/power/wakeup"
echo "suspend" > "$SYS_USB_DIR/2-1/power/level"

# Source the bashrc script
source ./bashrc

echo "--- Testing usb-on ---"
OUTPUT_ON=$(usb-on)
echo "$OUTPUT_ON"

if [[ "$OUTPUT_ON" != *"2-1 is now ON."* ]]; then
    echo "ERROR: usb-on output mismatch!" >&2
    exit 1
fi

if [[ $(cat "$SYS_USB_DIR/2-1/power/wakeup") != "disabled" ]]; then
    echo "ERROR: 2-1 power/wakeup was not set to disabled!" >&2
    exit 1
fi

if [[ $(cat "$SYS_USB_DIR/2-1/power/level") != "on" ]]; then
    echo "ERROR: 2-1 power/level was not set to on!" >&2
    exit 1
fi

echo "--- Testing usb-off ---"
OUTPUT_OFF=$(usb-off)
echo "$OUTPUT_OFF"

if [[ "$OUTPUT_OFF" != *"2-1 is now OFF."* ]]; then
    echo "ERROR: usb-off output mismatch!" >&2
    exit 1
fi

if [[ $(cat "$SYS_USB_DIR/2-1/power/level") != "suspend" ]]; then
    echo "ERROR: 2-1 power/level was not set to suspend!" >&2
    exit 1
fi

# Test when product attribute contains "GiN mbH" instead
rm -rf "$SYS_USB_DIR/2-1"
mkdir -p "$SYS_USB_DIR/usb1/power"
echo "Unknown" > "$SYS_USB_DIR/usb1/manufacturer"
echo "GiN mbH Logger" > "$SYS_USB_DIR/usb1/product"

OUTPUT_ON2=$(usb-on)
echo "$OUTPUT_ON2"
if [[ "$OUTPUT_ON2" != *"USB1 is now ON."* ]]; then
    echo "ERROR: usb-on product match mismatch!" >&2
    exit 1
fi

# Test when no GiN mbH device is present
rm -rf "$SYS_USB_DIR/usb1"
echo "--- Testing device not found ---"
if usb-on 2>/dev/null; then
    echo "ERROR: usb-on should have failed when device not present!" >&2
    exit 1
fi

echo "ALL TESTS PASSED SUCCESSFULLY!"
