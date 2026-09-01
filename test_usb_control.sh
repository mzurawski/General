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

echo "--- Testing usb-on.sh directly ---"
OUTPUT_ON=$(./usb-on.sh)
echo "$OUTPUT_ON"

if [[ "$OUTPUT_ON" != *"2-1 is now ON."* ]]; then
    echo "ERROR: usb-on.sh output mismatch!" >&2
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

echo "--- Testing usb-off.sh directly ---"
OUTPUT_OFF=$(./usb-off.sh)
echo "$OUTPUT_OFF"

if [[ "$OUTPUT_OFF" != *"2-1 is now OFF."* ]]; then
    echo "ERROR: usb-off.sh output mismatch!" >&2
    exit 1
fi

if [[ $(cat "$SYS_USB_DIR/2-1/power/level") != "suspend" ]]; then
    echo "ERROR: 2-1 power/level was not set to suspend!" >&2
    exit 1
fi

echo "--- Testing bashrc wrapper functions ---"
source ./bashrc

OUTPUT_WRAPPER_ON=$(usb-on)
echo "$OUTPUT_WRAPPER_ON"
if [[ "$OUTPUT_WRAPPER_ON" != *"2-1 is now ON."* ]]; then
    echo "ERROR: bashrc usb-on wrapper output mismatch!" >&2
    exit 1
fi

OUTPUT_WRAPPER_OFF=$(usb-off)
echo "$OUTPUT_WRAPPER_OFF"
if [[ "$OUTPUT_WRAPPER_OFF" != *"2-1 is now OFF."* ]]; then
    echo "ERROR: bashrc usb-off wrapper output mismatch!" >&2
    exit 1
fi

# Test when product attribute contains "GiN mbH" instead
rm -rf "$SYS_USB_DIR/2-1"
mkdir -p "$SYS_USB_DIR/usb1/power"
echo "Unknown" > "$SYS_USB_DIR/usb1/manufacturer"
echo "GiN mbH Logger" > "$SYS_USB_DIR/usb1/product"

OUTPUT_ON2=$(./usb-on.sh)
echo "$OUTPUT_ON2"
if [[ "$OUTPUT_ON2" != *"USB1 is now ON."* ]]; then
    echo "ERROR: usb-on.sh product match mismatch!" >&2
    exit 1
fi

# Test when no GiN mbH device is present
rm -rf "$SYS_USB_DIR/usb1"
echo "--- Testing device not found ---"
if ./usb-on.sh 2>/dev/null; then
    echo "ERROR: usb-on.sh should have failed when device not present!" >&2
    exit 1
fi

echo "ALL TESTS PASSED SUCCESSFULLY!"
