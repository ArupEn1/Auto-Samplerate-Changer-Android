#!/system/bin/sh
[ -f /data/adb/usb_dac_bitperfect/usb_offload_off ] && resetprop -n vendor.audio.feature.usb_offload.enable false
# finer media volume steps (bprate volsteps): only when a valid number is saved, otherwise nothing is touched
v=$(cat /data/adb/usb_dac_bitperfect/volsteps 2>/dev/null)
case "$v" in ""|*[!0-9]*) ;; *) [ "$v" -ge 16 ] && [ "$v" -le 150 ] && resetprop -n ro.config.media_vol_steps "$v" ;; esac
exit 0
