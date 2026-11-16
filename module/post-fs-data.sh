#!/system/bin/sh
[ -f /data/adb/usb_dac_bitperfect/usb_offload_off ] && resetprop -n vendor.audio.feature.usb_offload.enable false
exit 0
