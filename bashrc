# USB Power Control Functions
usb-on() {
    echo disabled | sudo tee /sys/bus/usb/devices/usb1/power/wakeup > /dev/null
    echo on | sudo tee /sys/bus/usb/devices/usb1/power/level > /dev/null
    echo "USB1 is now ON."
}

usb-off() {
    echo disabled | sudo tee /sys/bus/usb/devices/usb1/power/wakeup > /dev/null
    echo suspend | sudo tee /sys/bus/usb/devices/usb1/power/level > /dev/null
    echo "USB1 is now OFF."
}
