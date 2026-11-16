#!/system/bin/sh
# Helper for nsenter: nsenter's own option parser would swallow dash-prefixed arguments meant for the backend
# ("Unknown option 'bypass-offload-safer'"), so the arguments travel in $SR_ARGS instead.
exec "${BP_SH:-/system/bin/sh}" "$SR_DIR/USB_SampleRate_Changer.sh" $SR_ARGS
