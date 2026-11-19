#!/bin/sh
# Offline tests for the pure-text logic (policy patching, dump parsing, status line, rate picking).
# Needs: sh, awk, grep, sed. Run from repo root:  sh tests/run.sh
HERE=$(cd "$(dirname "$0")" && pwd)
FX=$HERE/fixtures
. "$HERE/../module/common.sh"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "ok   - $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL - $1"; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi; }
has()  { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (missing '$3' in '$2')" ;; esac; }
hasnt(){ case "$2" in *"$3"*) bad "$1 (unexpected '$3' in '$2')" ;; *) ok "$1" ;; esac; }
T=$(mktemp -d)

patch_policy "$FX/policy_stock.xml" "$T/p.xml" 44100
patch_ok "$FX/policy_stock.xml" "$T/p.xml" && ok "patch keeps line + mixPort counts" || bad "patch_ok"
has  "hifi_playback gets one static profile" "$(cat $T/p.xml)" 'name="hifi_playback" role="source"><profile name="" format="AUDIO_FORMAT_PCM_32_BIT" samplingRates="44100"'
hasnt "deep_buffer removed from USB Device route" "$(grep -A1 'sink="USB Device Out"' $T/p.xml)" deep_buffer
hasnt "deep_buffer removed from USB Headset route" "$(grep -A1 'sink="USB Headset Out"' $T/p.xml)" deep_buffer
has  "deep_buffer kept on Speaker route" "$(grep -A1 'sink="Speaker"' $T/p.xml)" deep_buffer
has  "sink port untouched" "$(cat $T/p.xml)" 'usb_surround_sound" role="sink"><profile name="" format="AUDIO_FORMAT_PCM_16_BIT" samplingRates="48000"'
looks_patched "$T/p.xml" && ok "looks_patched detects our edit" || bad "looks_patched (patched)"
looks_patched "$FX/policy_stock.xml" && bad "looks_patched (stock)" || ok "looks_patched ignores stock file"
patch_policy "$FX/policy_stock.xml" "$T/p96.xml" 96000
has  "rate is configurable" "$(cat $T/p96.xml)" 'samplingRates="96000"'

TRACK_DUMP_FILE=$FX/flinger_playing_384k.txt; export TRACK_DUMP_FILE
load_probe
check "384k case: thread"      "$thr"    AudioOut_5D
check "384k case: mixer rate"  "$mrate"  384000
check "384k case: source rate" "$trate"  96000
check "384k case: source fmt"  "$tfmt"   00000005
check "384k case: gain"        "$tgain"  -21
check "384k case: one active"  "$tcount" 1
s=$(status_line)
has "384k case: flags resampling" "$s" "RESAMPLED"
has "384k case: flags volume"     "$s" "VOLUME -21 dB"
has "384k case: USB advice is to use max volume" "$s" "set media volume to MAX"
check "384k case: device is usb" "$dev" usb
has "384k case: float source"     "$s" "float source"
TRACK_DUMP_FILE=$FX/flinger_playing_matched.txt; load_probe; s=$(status_line)
has   "matched case: rate-matched" "$s" "rate-matched"
hasnt "matched case: no resample flag" "$s" "RESAMPLED"
hasnt "matched case: no volume flag"   "$s" "VOLUME"
has   "matched case: 16-bit source"    "$s" "16-bit"
TRACK_DUMP_FILE=$FX/flinger_idle.txt; load_probe; has "idle case" "$(status_line)" "idle"

# experimental jack following (real dump from an LG V30+ playing a 44.1 kHz track on the 3.5 mm jack, bypass-offload)
TRACK_DUMP_FILE=$FX/flinger_jack_44k.txt; export TRACK_DUMP_FILE
BP_STATE=$T/jackstate; mkdir -p "$BP_STATE"
load_probe; check "jack flag off: jack thread ignored" "$thr" ""
has "jack flag off: status says no USB output" "$(status_line)" "No USB output"
touch "$BP_STATE/jack"
load_probe
check "jack: thread"      "$thr"    AudioOut_15
check "jack: mixer rate"  "$mrate"  44100
check "jack: source rate" "$trate"  44100
check "jack: one active"  "$tcount" 1
has "jack: rate-matched"  "$(status_line)" "rate-matched"
check "jack: device is jack" "$dev" jack
hasnt "jack: never tells the user to use max volume" "$(status_line)" "MAX"
has "jack: reports the volume gently" "$(status_line)" "keep it at a comfortable level"
has "jack: track table lists the headset thread" "$(usb_tracks)" "[AudioOut_15]"
check "jack pick 96000" "$(jack_pick_rate 96000)" 96000
check "jack pick 384000 -> 192000 (extended off)" "$(jack_pick_rate 384000)" 192000
check "extended off: rate cap" "$(rate_cap)" 192000
touch "$BP_STATE/extended"
check "extended on: rate cap" "$(rate_cap)" 384000
check "extended on: jack pick 384000 stays" "$(jack_pick_rate 384000)" 384000
check "extended on: jack pick 352800 stays" "$(jack_pick_rate 352800)" 352800
check "extended on: jack pick 192000 stays" "$(jack_pick_rate 192000)" 192000
check "extended on: jack pick 705600 -> 352800" "$(jack_pick_rate 705600)" 352800
rm -f "$BP_STATE/extended"
check "jack pick 352800 -> 176400" "$(jack_pick_rate 352800)" 176400
check "jack pick unknown rate -> none" "$(jack_pick_rate 22050)" ""
echo "--bypass-offload" > "$BP_STATE/sr_flags"; jack_mode_ok && ok "jack_mode_ok: bypass-offload" || bad "jack_mode_ok bypass-offload"
for m in bypass-offload-safer offload-safer safe safest safest-auto; do echo "--$m" > "$BP_STATE/sr_flags"; jack_mode_ok && bad "jack_mode_ok should refuse $m" || ok "jack_mode_ok refuses $m"; done

# per-output profiles (policy dumps from the V30+; the unplugged one is the plugged dump without the Wired Headset entry)
export BP_ASOUND=$T/asound; mkdir -p "$BP_ASOUND/card0"
POLICY_DUMP_FILE=$FX/policy_jack_plugged.txt; export POLICY_DUMP_FILE
check "out_kind: headset plugged -> jack" "$(out_kind)" jack
POLICY_DUMP_FILE=$FX/policy_jack_unplugged.txt
check "out_kind: unplugged -> other (the input-list headset mic does not count)" "$(out_kind)" other
sed 's/AUDIO_DEVICE_OUT_WIRED_HEADSET/AUDIO_DEVICE_OUT_WIRED_HEADPHONE/' $FX/policy_jack_plugged.txt > $T/headphone.txt
POLICY_DUMP_FILE=$T/headphone.txt
check "out_kind: headphones without mic -> jack" "$(out_kind)" jack
POLICY_DUMP_FILE=$T/empty.txt; : > "$T/empty.txt"
check "out_kind: unreadable dump -> nothing (not 'unplugged')" "$(out_kind)" ""
POLICY_DUMP_FILE=$FX/policy_bt.txt
check "out_kind: Bluetooth headset -> bt (not 'other', so profiles leave it alone)" "$(out_kind)" bt
POLICY_DUMP_FILE=$FX/policy_bt_jack.txt
check "out_kind: Bluetooth beats the jack" "$(out_kind)" bt
sed 's/BLUETOOTH_A2DP/BLUETOOTH_SCO/' $FX/policy_bt.txt > $T/sco_only.txt
POLICY_DUMP_FILE=$T/sco_only.txt
check "out_kind: SCO alone (phone-call headset) is not Bluetooth media" "$(out_kind)" other
sed 's/BLUETOOTH_A2DP/BLE_HEADSET/' $FX/policy_bt.txt > $T/ble.txt
POLICY_DUMP_FILE=$T/ble.txt
check "out_kind: LE Audio headset -> bt" "$(out_kind)" bt
POLICY_DUMP_FILE=$FX/policy_bt_jack.txt
mkdir -p "$BP_ASOUND/card1"; echo "1234:5678" > "$BP_ASOUND/card1/usbid"
check "out_kind: USB card beats the jack" "$(out_kind)" usb
rm -rf "$BP_ASOUND/card1"
unset BP_ASOUND POLICY_DUMP_FILE

PS=$T/profstate; mkdir -p "$PS"; BP_STATE=$PS
profiles_on && bad "profiles off by default" || ok "profiles off by default"
check "no profile set -> nothing pending" "$(prof_pending usb)" ""
prof_set jack bypass-offload 32 && ok "prof_set accepts mode + bits" || bad "prof_set jack"
check "prof_get returns mode:bits" "$(prof_get jack)" "bypass-offload:32"
prof_set other safest && ok "prof_set without bits uses the current bit depth" || bad "prof_set other"
check "bits default to the saved bit depth" "$(prof_get other)" "safest:32"
echo 24 > "$BP_STATE/sr_bits"; prof_set usb bypass-offload-safer; check "bits default follows sr_bits" "$(prof_get usb)" "bypass-offload-safer:24"
prof_set jack nonsense 32 && bad "prof_set must reject an unknown mode" || ok "prof_set rejects an unknown mode"
prof_set jack bypass-offload 8 && bad "prof_set must reject bad bits" || ok "prof_set rejects bad bits"
prof_set speaker safest 32 && bad "prof_set must reject an unknown output" || ok "prof_set rejects an unknown output"
check "a rejected set leaves the old profile alone" "$(prof_get jack)" "bypass-offload:32"
echo "--bypass-offload-safer" > "$BP_STATE/sr_flags"; echo 32 > "$BP_STATE/sr_bits"
check "jack profile differs from the mode in effect -> pending" "$(prof_pending jack)" "bypass-offload:32"
echo "--bypass-offload" > "$BP_STATE/sr_flags"
check "profile already in effect -> nothing pending" "$(prof_pending jack)" ""
check "other profile pending when jack mode is in effect" "$(prof_pending other)" "safest:32"
check "unknown output has no profile" "$(prof_get ../x)" ""
rm -f "$BP_STATE/prof_usb" "$BP_STATE/prof_other"
jack_on && bad "jack_on false: no flag, profiles off" || ok "jack_on false without flag or profiles"
touch "$BP_STATE/profiles"
jack_on && ok "jack_on true: profiles on and a jack profile exists" || bad "jack_on with jack profile"
rm -f "$BP_STATE/prof_jack"
jack_on && bad "jack_on false: profiles on but no jack profile" || ok "jack_on false: profiles on, no jack profile"
BP_KIND=usb; check "BP_KIND=usb narrows the output regex" "$(out_re)" "AUDIO_DEVICE_OUT_USB"
BP_KIND=jack; check "BP_KIND=jack narrows the output regex" "$(out_re)" "AUDIO_DEVICE_OUT_WIRED_HEAD"
BP_KIND=other; check "other output: status line says nothing to follow" "$(status_line)" "Speaker/other output | mode --bypass-offload | nothing to follow"
BP_KIND=bt; check "Bluetooth output: status line says nothing to follow" "$(status_line)" "Bluetooth output | mode --bypass-offload | nothing to follow"
check "Bluetooth with no profile: nothing pending" "$(prof_pending bt)" ""
BP_KIND=bt; echo "--safest" > "$BP_STATE/sr_flags"
check "Bluetooth in safest: status line warns" "$(status_line)" "Bluetooth output | mode --safest | nothing to follow | safest does not play on Bluetooth: set a Bluetooth profile"
echo "--bypass-offload" > "$BP_STATE/sr_flags"
prof_set bt bypass-offload-safer 32 && ok "prof_set accepts the bt output" || bad "prof_set bt"
check "bt profile pending when another mode is in effect" "$(prof_pending bt)" "bypass-offload-safer:32"
rm -f "$BP_STATE/prof_bt"
unset BP_KIND
TRACK_DUMP_FILE=$FX/flinger_jack_44k.txt; BP_KIND=usb; load_probe; check "BP_KIND=usb ignores the jack thread" "$thr" ""
BP_KIND=jack; load_probe; check "BP_KIND=jack finds the jack thread" "$thr" AudioOut_15
unset BP_KIND
# timing clock: numeric and never goes backwards
a=$(now_ms); sleep 0.2; b=$(now_ms)
case "$a$b" in *[!0-9]*|"") bad "now_ms is numeric" ;; *) ok "now_ms is numeric" ;; esac
[ "$b" -gt "$a" ] && [ $((b - a)) -lt 2000 ] && ok "now_ms moves forward by about the time slept" || bad "now_ms forward ($a -> $b)"
# the 96 kHz lock: asked for more than 96 kHz, mixer stuck at or under 96 kHz
lock_signature 192000 96000 && ok "lock: 192000 asked, mixer at 96000" || bad "lock 192000/96000"
lock_signature 384000 48000 && ok "lock: 384000 asked, mixer at 48000" || bad "lock 384000/48000"
lock_signature 192000 192000 && bad "no lock when the mixer reached the rate" || ok "no lock when the mixer reached the rate"
lock_signature 96000 96000 && bad "no lock when only 96000 was asked" || ok "no lock when only 96000 was asked"
lock_signature 192000 "" && bad "no lock without a mixer reading" || ok "no lock without a mixer reading"
lock_signature 192000 x && bad "no lock on a non-numeric reading" || ok "no lock on a non-numeric reading"
# unlocker modules (zyhk: usb-samplerate-unlocker / audio-samplerate-changer / hifi-maximizer-mod)
BP_MODROOT=$T/modroot; mkdir -p "$BP_MODROOT"; export BP_MODROOT
unlocker_present && bad "no unlocker module -> not present" || ok "no unlocker module -> not present"
for um in usb-samplerate-unlocker audio-samplerate-changer hifi-maximizer-mod; do
  mkdir "$BP_MODROOT/$um"; unlocker_present && ok "unlocker_present sees $um" || bad "unlocker_present misses $um"; rmdir "$BP_MODROOT/$um"
done
mkdir "$BP_MODROOT/some-other-module"; unlocker_present && bad "an unrelated module is not an unlocker" || ok "an unrelated module is not an unlocker"
unset BP_MODROOT
# volume steps (off by default; valid range 16..150)
VS=$T/vs; mkdir -p "$VS"; _bs=$BP_STATE; BP_STATE=$VS
check "volsteps: nothing saved -> off" "$(volsteps_get)" ""
for v in 16 30 100 150; do volsteps_valid $v && ok "volsteps_valid $v" || bad "volsteps_valid $v"; done
for v in 15 151 0 abc "" 3.5 -20 1e2; do volsteps_valid "$v" && bad "volsteps must reject '$v'" || ok "volsteps rejects '$v'"; done
echo 75 > "$VS/volsteps"; check "volsteps: saved value is read" "$(volsteps_get)" 75
echo 999 > "$VS/volsteps"; check "volsteps: a bad saved value counts as off" "$(volsteps_get)" ""
rm -f "$VS/volsteps"
check "vol_parse: media_session text" "$(echo 'volume is 7 in range [0..15]' | vol_parse)" "7 15"
check "vol_parse: 150 steps" "$(echo 'volume is 112 in range [0..150]' | vol_parse)" "112 150"
check "vol_parse: unknown text -> nothing" "$(echo 'Error: something else' | vol_parse)" ""
BP_STATE=$_bs
unset BP_STATE; TRACK_DUMP_FILE=$FX/flinger_idle.txt

check "pick 44100" "$(pick_rate 44100 $FX/stream0_dac.txt)" 44100
check "pick 96000" "$(pick_rate 96000 $FX/stream0_dac.txt)" 96000
check "88200 unsupported -> none" "$(pick_rate 88200 $FX/stream0_dac.txt)" ""
# the extended-rates switch is for the jack only: a USB DAC always uses the rates it lists (this fixture lists 192000 and 384000)
EX=$T/exstate; mkdir -p "$EX"; _bs=$BP_STATE; BP_STATE=$EX
check "USB, switch off: a 384000 track gets 384000" "$(pick_rate 384000 $FX/stream0_dac.txt)" 384000
check "USB, switch off: 192000 stays 192000" "$(pick_rate 192000 $FX/stream0_dac.txt)" 192000
touch "$EX/extended"
check "USB, switch on: a 384000 track gets 384000" "$(pick_rate 384000 $FX/stream0_dac.txt)" 384000
check "USB: 352800 track the DAC lacks -> none" "$(pick_rate 352800 $FX/stream0_dac.txt)" ""
BP_STATE=$_bs

POLICY_DUMP_FILE=$FX/policy_effects.txt; export POLICY_DUMP_FILE
check "only enabled effects reported" "$(active_effects)" "Volume listener for Music"

check "sanitize_report strips pid/uid and pointers" "$(printf '  58 yes 4990/  10198 0xb4000072110939f0\n' | sanitize_report)" "  58 yes <pid>/<uid> <ptr>"

# primary-output trim (opt-in)
mkdir -p "$T/state"; BP_STATE=$T/state; export BP_STATE
patch_policy "$FX/policy_stock.xml" "$T/np.xml" 44100
has "primary output kept by default on USB route" "$(grep -A1 'sink="USB Device Out"' $T/np.xml)" "primary output"
touch "$BP_STATE/trim_primary"
patch_policy "$FX/policy_stock.xml" "$T/tp.xml" 44100
hasnt "primary output removed from USB Device route when trimmed" "$(grep -A1 'sink="USB Device Out"' $T/tp.xml)" "primary output"
hasnt "primary output removed from USB Headset route when trimmed" "$(grep -A1 'sink="USB Headset Out"' $T/tp.xml)" "primary output"
has "hifi_playback still on USB route when trimmed" "$(grep -A1 'sink="USB Device Out"' $T/tp.xml)" "hifi_playback"
has "primary output kept on Speaker route when trimmed" "$(grep -A1 'sink="Speaker"' $T/tp.xml)" "primary output"
patch_ok "$FX/policy_stock.xml" "$T/tp.xml" && ok "trimmed patch is sane" || bad "trimmed patch_ok"
patch_ok /nonexistent "$T/tp.xml" && bad "patch_ok accepts missing source" || ok "patch_ok rejects missing source"

# backend mode: apply_rate drives the bundled USB_SampleRate_Changer with flags/rate/bits from the state dir
BP_MODDIR=$T/mod; mkdir -p "$BP_MODDIR"; export BP_MODDIR
mocksr() { echo "$*" > "$T/sr_args"; return ${MOCK_RC:-0}; }
BP_SR_CMD=mocksr; export BP_SR_CMD
check "default flags"  "$(sr_flags)" "--bypass-offload-safer"
check "default bits"   "$(sr_bits)"  "32"
apply_rate 96000
check "apply_rate passes default flags, rate, bits" "$(cat $T/sr_args)" "--bypass-offload-safer 96000 32"
check "apply_rate records new rate" "$(cat $BP_STATE/rate)" 96000
echo "--bypass-offload" > "$BP_STATE/sr_flags"; echo 24 > "$BP_STATE/sr_bits"
apply_rate 48000
check "apply_rate honours saved mode and bits" "$(cat $T/sr_args)" "--bypass-offload 48000 24"
MOCK_RC=1 apply_rate 192000; rc=$?
check "failed backend returns non-zero" "$rc" 1
check "failed backend does not record the rate" "$(cat $BP_STATE/rate)" 48000
touch "$BP_STATE/drc"; echo "--bypass-offload-safer" > "$BP_STATE/sr_flags"; echo 32 > "$BP_STATE/sr_bits"
apply_rate 44100
check "apply_rate adds --drc as a separate argument when enabled" "$(cat $T/sr_args)" "--bypass-offload-safer --drc 44100 32"
rm -f "$BP_STATE/drc"
apply_rate 44100
check "apply_rate omits --drc by default" "$(cat $T/sr_args)" "--bypass-offload-safer 44100 32"
unset BP_SR_CMD MOCK_RC
BP_SRDIR=$T/nonexistent; export BP_SRDIR; SR_DIR=$BP_SRDIR
sr_run 44100 >/dev/null 2>&1; rc=$?
check "sr_run fails cleanly when the bundled backend is missing" "$rc" 1
unset BP_SRDIR; SR_DIR=$HERE/../module/usbsrc
[ -f "$SR_DIR/USB_SampleRate_Changer.sh" ] && [ -f "$SR_DIR/functions3.shlib" ] && [ -d "$SR_DIR/templates" ] && ok "bundled backend files are present" || bad "bundled backend files missing"
# functions3.shlib uses the "function" keyword (fine for Android mksh, not for dash), so only the main script is syntax-checked here
sh -n "$SR_DIR/USB_SampleRate_Changer.sh" && ok "bundled backend script parses" || bad "bundled backend script syntax"
for t in bypass_offload_safer_template bypass_offload_template offload_hifi_playback_template offload_template; do
  [ -f "$SR_DIR/templates/$t.xml" ] && ok "template $t present" || bad "template $t missing"
done
# nsenter regression: Android's nsenter parses dash-prefixed arguments after the command as its own options
mkdir -p "$T/fakebin" "$T/fakesr"
cat > "$T/fakebin/nsenter" <<'NSE'
#!/bin/sh
# fake nsenter: skip "-t 1 -m", then refuse any dash-prefixed argument (like toybox does), else run the command
[ "$1" = -t ] && shift 2; [ "$1" = -m ] && shift
cmd=$1; shift
for a in "$@"; do case "$a" in -*) echo "nsenter: Unknown option '${a#-}' (see \"nsenter --help\")" >&2; exit 1 ;; esac; done
exec "$cmd" "$@"
NSE
chmod +x "$T/fakebin/nsenter"
SR_RECORD=$T/sr_ns_args   # baked into the stub: env -i wipes the environment, as in real use
printf '#!/bin/sh\necho "$*" > %s\n' "$SR_RECORD" > "$T/fakesr/USB_SampleRate_Changer.sh"
BP_SRDIR=$T/fakesr; SR_DIR=$BP_SRDIR; BP_SR_PATH="$T/fakebin:/usr/bin:/bin"; BP_SH=/bin/sh; BP_SRWRAP=$HERE/../module/sr_wrap.sh; BP_FORCE_NS=1
export BP_SRDIR BP_SR_PATH BP_SH BP_SRWRAP BP_FORCE_NS
rm -f "$SR_RECORD"
sr_run --bypass-offload-safer 96000 32; rc=$?
check "sr_run through nsenter succeeds" "$rc" 0
check "backend receives its dash-prefixed arguments intact via nsenter" "$(cat $SR_RECORD 2>/dev/null)" "--bypass-offload-safer 96000 32"
unset BP_SRDIR BP_SR_PATH BP_SH BP_SRWRAP BP_FORCE_NS; SR_DIR=$HERE/../module/usbsrc
# pause/resume helper: media_session first, media key as fallback
cmd() { echo "cmd $*" >> "$T/media.log"; return ${CMD_RC:-0}; }
input() { echo "input $*" >> "$T/media.log"; }
: > "$T/media.log"; media_cmd pause; media_cmd play
check "media_cmd uses media_session" "$(cat $T/media.log | tr '\n' '|')" "cmd media_session dispatch pause|cmd media_session dispatch play|"
: > "$T/media.log"; CMD_RC=1 media_cmd pause; CMD_RC=1 media_cmd play
check "media_cmd falls back to media keys 127/126" "$(cat $T/media.log | tr '\n' '|')" "cmd media_session dispatch pause|input keyevent 127|cmd media_session dispatch play|input keyevent 126|"
media_cmd bogus 2>/dev/null; check "media_cmd rejects unknown commands" "$?" 1
check "default pause delay" "$(pause_delay)" "1.5"
echo 2 > "$BP_STATE/pause_delay"; check "saved pause delay" "$(pause_delay)" "2"
unset -f cmd input
unset BP_MODDIR BP_STATE

# WebUI
WU=$HERE/../module/webroot/index.html
[ -f "$WU" ] && ok "webui page present" || bad "webui page missing"
grep -q 'ksu.exec' "$WU" && ok "webui uses the ksu.exec bridge" || bad "webui bridge missing"
for c in state auto boot drc pause fast jack extended volsteps profiles profile mode bits reset; do
  grep -q "bprate" "$WU" && grep -qE "^ *\"?$c\"?\)|^ *([a-z0-9|-]+\|)?$c(\|[a-z0-9-]+)*\)" "$HERE/../module/system/bin/bprate" && ok "bprate handles '$c' (used by webui)" || bad "bprate lacks '$c'"
done

grep -q 'bpreport' "$WU" && [ -f "$HERE/../module/system/bin/bpreport" ] && ok "webui report button has its tool" || bad "report button/tool missing"

# WebUI themes
for th in light dark retro crt; do grep -q "data-theme=$th" "$WU" && ok "webui has '$th' theme" || bad "webui lacks '$th' theme"; done
[ -s "$HERE/../module/webroot/fonts/asc-pixel.ttf" ] && grep -q 'fonts/asc-pixel.ttf' "$WU" && ok "retro pixel font present and referenced" || bad "pixel font missing"
grep -q 'data-anim' "$WU" && grep -q 'id="animSw"' "$WU" && ok "webui has animation toggle" || bad "animation toggle missing"
grep -q 'localStorage' "$WU" && grep -q 'try{' "$WU" && ok "theme storage is guarded" || bad "theme storage unguarded"

# lint: a literal backslash-n glued to a command/word is a broken line break (bpdiag/bpcheck had this)
bad_nl=$(grep -nE '\\n[a-z_.]' "$HERE"/../module/*.sh "$HERE"/../module/system/bin/*)
[ -z "$bad_nl" ] && ok "no broken literal line breaks in module scripts" || bad "broken literal line breaks: $bad_nl"

rm -rf "$T"
echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" = 0 ]
