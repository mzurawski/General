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
echo "auto" > "$SYS_USB_DIR/1-1/power/control"

# Create mock USB device 2 (GiN mbH with power/control attribute)
mkdir -p "$SYS_USB_DIR/2-1/power"
echo "GiN mbH" > "$SYS_USB_DIR/2-1/manufacturer"
echo "GiN CAN Bus Interface" > "$SYS_USB_DIR/2-1/product"
echo "enabled" > "$SYS_USB_DIR/2-1/power/wakeup"
echo "on" > "$SYS_USB_DIR/2-1/power/control"

echo "--- Testing usb-off.sh with power/control ---"
OUTPUT_OFF=$(./usb-off.sh)
echo "$OUTPUT_OFF"

if [[ "$OUTPUT_OFF" != *"2-1 is now OFF."* ]]; then
    echo "ERROR: usb-off.sh output mismatch!" >&2
    exit 1
fi

if [[ $(cat "$SYS_USB_DIR/2-1/power/control") != "auto" ]]; then
    echo "ERROR: 2-1 power/control was not set to auto!" >&2
    exit 1
fi

echo "--- Testing usb-on.sh with power/control ---"
OUTPUT_ON=$(./usb-on.sh)
echo "$OUTPUT_ON"

if [[ "$OUTPUT_ON" != *"2-1 is now ON."* ]]; then
    echo "ERROR: usb-on.sh output mismatch!" >&2
    exit 1
fi

if [[ $(cat "$SYS_USB_DIR/2-1/power/control") != "on" ]]; then
    echo "ERROR: 2-1 power/control was not set to on!" >&2
    exit 1
fi

# Test legacy power/level attribute
rm -rf "$SYS_USB_DIR/2-1"
mkdir -p "$SYS_USB_DIR/3-1/power"
echo "GiN mbH" > "$SYS_USB_DIR/3-1/manufacturer"
echo "on" > "$SYS_USB_DIR/3-1/power/level"

echo "--- Testing legacy power/level ---"
OUTPUT_OFF_LEGACY=$(./usb-off.sh)
echo "$OUTPUT_OFF_LEGACY"
if [[ $(cat "$SYS_USB_DIR/3-1/power/level") != "suspend" ]]; then
    echo "ERROR: 3-1 power/level was not set to suspend!" >&2
    exit 1
fi

OUTPUT_ON_LEGACY=$(./usb-on.sh)
echo "$OUTPUT_ON_LEGACY"
if [[ $(cat "$SYS_USB_DIR/3-1/power/level") != "on" ]]; then
    echo "ERROR: 3-1 power/level was not set to on!" >&2
    exit 1
fi

# Test when no GiN mbH device is present
rm -rf "$SYS_USB_DIR/3-1"
echo "--- Testing device not found ---"
if ./usb-on.sh 2>/dev/null; then
    echo "ERROR: usb-on.sh should have failed when device not present!" >&2
    exit 1
fi

echo "ALL TESTS PASSED SUCCESSFULLY!"
