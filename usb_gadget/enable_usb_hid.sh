#!/bin/bash
# run this script under sudo permistion
#  /boot/config.txt: dtoverlay=dwc2,dr_mode=peripheral
#  /boot/cmdline.txt: modules-load=dwc2,g_hid,g_serial
# https://forums.raspberrypi.com/viewtopic.php?t=341244
# https://learn.adafruit.com/turning-your-raspberry-pi-zero-into-a-usb-gadget?view=all
# https://github.com/ev3dev/ev3-systemd/blob/ev3dev-buster/scripts/ev3-usb.sh#L28
# https://gist.github.com/geekman/5bdb5abdc9ec6ac91d5646de0c0c60c4
# https://github.com/qlyoung/keyboard-gadget/blob/master/gadget-setup.sh
#
# /usr/lib/systemd/system/myusbgadget.service
# sudo cp myusbgadget.service /usr/lib/systemd/system/
# sudo systemctl start myusbgadget.service
# sudo systemctl enable myusbgadget.service
# sudo systemctl enable getty@ttyGS0.service
modprobe libcomposite

cd /sys/kernel/config/usb_gadget/
mkdir -p usb
cd usb
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB # USB2
mkdir -p strings/0x409
echo "0123456789" > strings/0x409/serialnumber
echo "Manufacturer" > strings/0x409/manufacturer
echo "USB device" > strings/0x409/product
mkdir -p configs/c.1/strings/0x409
echo "Config 1: ECM network" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

mkdir -p functions/hid.usb0
echo 1 > functions/hid.usb0/protocol
echo 1 > functions/hid.usb0/subclass
echo 8 > functions/hid.usb0/report_length
echo -ne \\x05\\x01\\x09\\x06\\xa1\\x01\\x05\\x07\\x19\\xe0\\x29\\xe7\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x08\\x81\\x02\\x95\\x01\\x75\\x08\\x81\\x03\\x95\\x05\\x75\\x01\\x05\\x08\\x19\\x01\\x29\\x05\\x91\\x02\\x95\\x01\\x75\\x03\\x91\\x03\\x95\\x06\\x75\\x08\\x15\\x00\\x25\\x65\\x05\\x07\\x19\\x00\\x29\\x65\\x81\\x00\\xc0 > functions/hid.usb0/report_desc
ln -s functions/hid.usb0 configs/c.1/
# serial
mkdir -p functions/acm.usb0    # serial
ln -s functions/acm.usb0 configs/c.1/

ls /sys/class/udc > UDC #  bind gadget to UDC driver (brings gadget online). This will only
                        #  succeed if there are no gadgets already bound to the driver. Do
                        #  lsmod and if there's anything in there like g_*, you'll need to
                        #  rmmod it before bringing this gadget online. Otherwise you'll get
                        #  "device or resource busy."
