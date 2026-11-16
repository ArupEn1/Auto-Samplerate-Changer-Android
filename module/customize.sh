#!/system/bin/sh
# v0.10: installs the control tools and the bundled USB_SampleRate_Changer. It changes nothing in /vendor.
SKIPUNZIP=0
ILOG=/data/local/tmp/bitperfect_install.log
: > "$ILOG"
_up() { ui_print "$1"; echo "$1" >> "$ILOG"; }
STATE=/data/adb/usb_dac_bitperfect
_up "- Auto Samplerate Changer for Android v0.6.13 (with optional bit-perfect, experimental)"
_up "  policy rewrite by the bundled USB_SampleRate_Changer (zyhk, AGPL-3.0, unmodified)"
[ "$API" -ge 36 ] || _up "! Tested on Android 16+ (API 36+); this device is API $API"
mkdir -p "$STATE"
[ -f "$STATE/rate" ]     || echo 44100 > "$STATE/rate"
[ -f "$STATE/sr_flags" ] || echo "--bypass-offload-safer" > "$STATE/sr_flags"
[ -f "$STATE/sr_bits" ]  || echo 32 > "$STATE/sr_bits"
[ -f "$STATE/boot_apply" ] || touch "$STATE/boot_apply"
# pause the player around a rate switch (default ON, 1.5 s): bprate pause on|off|<seconds>
if [ ! -f "$STATE/pause_delay" ]; then echo 1.5 > "$STATE/pause_delay"; touch "$STATE/pause"; fi
# per-track follow starts OFF after an update until you have checked it works: bprate auto on
rm -f "$STATE/auto" "$STATE/notify"; cmd notification cancel bitperfect >/dev/null 2>&1
set_perm_recursive "$MODPATH" 0 0 0755 0644
for s in system/bin/bpcheck system/bin/bprate system/bin/bpfollow system/bin/bpdiag system/bin/bpoffload system/bin/bpstatus system/bin/bpdump system/bin/bpverify system/bin/bpreport post-fs-data.sh service.sh sr_wrap.sh uninstall.sh usbsrc/USB_SampleRate_Changer.sh; do
  set_perm "$MODPATH/$s" 0 0 0755
done
cp "$ILOG" "$MODPATH/install.log" 2>/dev/null; cp "$ILOG" /sdcard/Download/bitperfect_install.log 2>/dev/null
_up "- Mode: $(cat $STATE/sr_flags), $(cat $STATE/rate) Hz, $(cat $STATE/sr_bits)-bit, applied at every boot."
_up "- WebUI: open the module in your root manager (APatch/KernelSU) and tap the WebUI button for buttons instead of commands."
_up "- IMPORTANT: Auto-follow is OFF after installing. Open the WebUI > Auto tab and turn on Auto-follow track rate, or sample rates will not change by themselves."
_up "- Done. Reboot, plug the DAC, play a track, then: su -c bpstatus"
