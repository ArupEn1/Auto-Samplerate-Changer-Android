#!/system/bin/sh
MODDIR=${0%/*}
STATE=/data/adb/usb_dac_bitperfect
. "$MODDIR/common.sh"
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done
sleep 10
# apply the saved mode/rate (the script's bind mount does not survive a reboot)
if [ -f "$STATE/boot_apply" ]; then
  { echo "boot apply $(date): $(sr_flags) $(cat $STATE/rate) $(sr_bits) drc=$([ -f $STATE/drc ] && echo on || echo off)"; apply_rate "$(cat $STATE/rate)"; echo "exit=$?"; } > "$STATE/boot.log" 2>&1
fi
[ -f "$STATE/auto" ] && "$MODDIR/system/bin/bpfollow" &
