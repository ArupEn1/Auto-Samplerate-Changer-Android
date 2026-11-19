# Changelog

Versions are module versions (`module/module.prop`). Nothing here is a validated release.

## 0.7.1

### Fixed
- **Bluetooth headphones and per-output profiles**: a Bluetooth headset used to count as "Speaker / other", so with the speaker profile on `safest` (which does not play on Bluetooth) connecting headphones left the sound on the speaker or jack. Bluetooth (A2DP, LE Audio, hearing aid) is now detected on its own and gets its own profile (`bprate profile bt <mode>`, Bluetooth row on the Auto tab; left on "keep current mode" it is not touched). It wins over the jack, and the follower does nothing on it. The Status tab warns when `safest` is in effect on Bluetooth. Seen on a Moto Edge 30 Fusion, an LG V30+ and a Samsung (all list the AirPods as `BLUETOOTH_A2DP`); `safest` stayed silent on the Moto and the LG, `bypass-offload` and `bypass-offload-safer` played.

### New
- Off by default: **finer media volume steps** (`bprate volsteps off|16..150`, card on the Audio tab). Sets `ro.config.media_vol_steps` at boot (up to 150 steps instead of Android's 15); handy for Bluetooth headphones or a USB DAC without a volume control of its own, where the phone's volume is the only control. Needs a reboot, and `off` changes nothing. The setting is kept in the state dir, so it survives module updates. `bpstatus` and the Status tab show the media volume as `Media volume: N / M`. Worked with 75 and 150 steps on a Moto Edge 30 Fusion (LineageOS 24).

### Changed
- Auto tab: the per-output rows only show once "Switch mode by output" is on; the card explains what it does while it is off.
- README: the Auto-follow description now covers the jack, the profiles and the extended rates; new Auto tab screenshots.
- Docs: Poweramp followed 352.8 and 384 kHz on the jack with the extended rates switch on.

## 0.7.0

The module now reaches beyond USB: it can follow the 3.5 mm jack and switch modes per output. Both are experimental and off by default. They were tested on an LG V30+ (LineageOS 22.2, Magisk).

### New
- **Follow the 3.5 mm jack** (experimental): `bprate jack on`, or the switch on the Auto tab. With no USB DAC, the follower reads the wired-headset output thread and sets the mixer to the track's rate. It does nothing in modes that keep the jack at 48 kHz (`bypass-offload-safer`, `offload-safer`, `safe`, `safest`, `safest-auto`) and logs a note. On the V30+ it switched to 44.1, 48 and 192 kHz as tracks changed, and at 192 kHz the headphone output thread and the kernel stream both ran at 192000 Hz.
- **Per-output profiles** (experimental): `bprate profiles on`, `bprate profile usb|jack|other <mode> [bits]`, or the card on the Auto tab. Each output (USB DAC, 3.5 mm jack, speaker/other) gets its own mode and bit depth, and the follower switches when the output changes. Nothing is preset, and an output without a profile is left alone. The output has to stay the same for two checks before a switch, an unreadable dump never counts as an unplug, and more than 4 switches in 2 minutes or two backend failures turn profiles off. A jack profile also turns on jack following. On the V30+ it switched jack (`bypass-offload`) and speaker (`safest`) correctly when headphones were plugged and unplugged (about 5 s), and on a USB DAC (`bypass-offload-safer`) it switched and kept following the track rate.
- **Unlock extended sample rates (jack)** (`bprate extended on|off`, Auto tab): off by default, so the jack is never asked for more than 192 kHz (a track above that is followed at half its rate, once). On: 352.8 and 384 kHz are allowed for the jack, and the Rate tab shows 352.8 and 384 kHz buttons. The V30+ jack accepted 384 kHz (output thread and kernel stream both at 384000 Hz, normal sound). USB DACs are not affected: they use the rates the DAC lists.
- **USB driver limit notice**: the Status tab shows a small card when the 96 kHz USB driver lock is detected, meaning bpfollow asked a USB DAC for more than 96 kHz and the mixer stayed at 96 kHz or lower. It names zyhk's usb-samplerate-unlocker, hides itself when an unlock module is installed (usb-samplerate-unlocker, audio-samplerate-changer or hifi-maximizer-mod), and can be dismissed. The follow log says the same.

### Changed
- On the 3.5 mm jack, a volume below max is reported without the "set media volume to MAX" advice. That advice stays for USB DACs.
- The `detect` and `restart` times in the follow log come from `/proc/uptime`, so they no longer go negative when the clock steps after an audio server restart.
- The Status tab reloads the settings every 6 seconds while auto refresh is on.
- `bpverify` (and so the report) shows the audio policy source (`dumpsys media.audio_policy` "Config source"). `bprate state` also prints `jack`, `extended`, `profiles`, the profile of each output, `unlocker` and `lockseen`.

### Fixed and hardened
- On "Recent AIDL only devices are not supported" the follower now logs a clear message and turns auto-follow off at once, resuming the player first, instead of retrying.
- The module's own temporary files (report, diagnostics, installer log) now go in the root-only `/data/adb/usb_dac_bitperfect/` instead of the shell-writable `/data/local/tmp` (avoids a symlink overwrite by the adb shell user). `load_probe` only accepts plain tokens from `dumpsys` text before assigning them.

### Docs
- README: Screenshots section, what happens when several apps play at once, the 96 kHz USB driver lock and the unlock module (Compatible Magisk-mirroring is needed first on APatch and recent Magisk), the jack and profile sections, and AIDL-only devices (for example the Galaxy Z Fold8) listed as not supported.
- docs/COMPATIBILITY.md: LG V30+ results for the jack, 384 kHz and profiles; Moto Edge 30 Fusion result with the unlocker; "Not supported: AIDL-only audio HAL".

## 0.6.14
- README: new section "How it knows the track's sample rate" (AudioFlinger track table, polling and confirmation, switch limits, what has and has not been tested).
- README: link to the SampleRate Support Group Discord server in "Reporting issues".
- Wording: the project is now called beta instead of experimental (module description, installer banner, README badge, release title).

## 0.6.13
- The EQ note lives in the README only; the WebUI Help page no longer states it. README now says EQ was confirmed working by the maintainer.

## 0.6.12
- Docs and WebUI Help: an EQ or parametric EQ still works (effects are not bypassed or forced off). Resampling stays stopped, but output is not bit-perfect while an EQ is on.

## 0.6.11
- WebUI: removed the Theme button from the header so it cannot be tapped by accident when reaching for Help. Themes are chosen in Tools > Appearance.

## 0.6.10
- WebUI: the Help page is now opened with a "? Help" button in the top corner (next to the theme button) instead of its own tab. It slides up over the page and has a Close button (Esc also closes it).

## 0.6.9
- WebUI: the quick start now has its own **Help** tab (quick start, troubleshooting, what each tab does). The Status tab shows an "Auto-follow is off" card with a one-tap button until Auto-follow is turned on. The installer and README now say clearly that Auto-follow is off after installing.

## 0.6.8
- WebUI: a collapsible "Quick start: 4 steps" card on the Status tab (remembers if you close it) and a "Which mode should I pick?" help card on the Audio tab, in plain words.
- Docs: all terminal commands moved to `docs/TERMINAL.md`; the README Quick start now uses the WebUI.

## 0.6.7
- License: the project is now offered under AGPL-3.0 (one license with the bundled AGPL-3.0 backend; GPL-3.0 section 13 allows combining it with the GPL-3.0 base). The GPL-3.0 text of the original base is kept in `LICENSES/GPL-3.0.txt`.

## 0.6.6
- Author name in module.prop, NOTICE and README is now ArupEn1 (matches the GitHub handle). README rewritten for publishing, with acknowledgements.

## 0.6.5
- WebUI: removed the pulsing glow on the "Rate-matched" badge (distracting).

## 0.6.4
- WebUI animations are slower and softer (about 0.65 s card fade-in with a longer stagger, slower badge pulse and theme colour fade, gentler cursor blink).

## 0.6.3
- WebUI animation smoothness: all motion now uses only GPU-composited properties (transform and opacity). The badge glow no longer animates a shadow, the Retro themes no longer use stepped (choppy) motion, and colour fades run only for a moment when switching themes. The page cannot set the screen refresh rate itself; that is up to the phone and the root manager app.

## 0.6.2
- WebUI animations in every theme: cards rise in on tab change, smooth colour fade when switching themes, soft glow on the "Rate-matched" badge, hover lift on buttons. Retro themes use stepped, pixel-style motion and Retro night gets a blinking cursor. A new Tools > Appearance > Animations switch turns it all off (saved on the device; defaults to off if the system asks for reduced motion).

## 0.6.1
- WebUI: new "Retro night" theme (amber phosphor terminal look on near-black, faint scanlines). Same pixel font; no animation.

## 0.6.0
- WebUI themes: Auto (follows the system), Day, Night and Retro (yellowed old-paper look with a pixel font). Pick one in Tools > Appearance; the choice is saved on the device only.
- Bundled pixel font `module/webroot/fonts/asc-pixel.ttf` is an original 5x7 bitmap font made for this project (generator script included next to it), released as CC0 / public domain. No third-party fonts are used.
- Docs: the LG V30 (LineageOS 22.2) result was obtained on Magisk.

## 0.5.2
- WebUI: when the only enabled effect is the vendor "Volume listener" (common on Qualcomm phones such as the LG V30), the yellow badge reads "Vendor volume listener (may differ on LG phones)" instead of "Sound effects on". Any other effect still shows "Sound effects on".

## 0.5.1
- Modes `usb-only` and `safest-auto` can now be selected (`bprate mode usb-only`, WebUI Audio tab). `usb-only` changes only `/vendor/etc/usb_audio_policy_configuration.xml` and leaves the main audio policy alone; added after the default mode left an LG V30 (LineageOS 22.2, Magisk) without speaker sound, because the backend's default modes replace the whole policy with a generic template.
- `bpverify` also shows the USB policy file.

## 0.5 (first release)

- **Auto-follow:** a small daemon watches the playing track and switches the USB mixer to that track's sample rate, so music is not resampled.
- **Backend:** the policy rewrite is done by zyhk's [USB_SampleRate_Changer](https://github.com/yzyhk904/USB_SampleRate_Changer) (AGPL-3.0), bundled unmodified in `module/usbsrc` with its license. This module adds boot-time apply, rate following, pause/resume around switches, a WebUI and the diagnostic tools around it.
- **Pause during switch:** optionally pauses the player just before a rate change and resumes after the audio server is back (default 1.5 s); optional fast detection.
- **WebUI:** Status, Rate, Auto, Audio and Tools tabs; save a full report to Downloads; yellow heads-up badges for enabled sound effects or a volume drop.
- **Options:** mode (default `bypass-offload-safer`), bit depth (default 32), DRC (default off, not bit-perfect), apply at boot, `bprate reset` to undo everything.
- **Tools:** `bpstatus`, `bpcheck`, `bprate`, `bpverify`, `bpdiag`, `bpreport`, `bpdump`, `bpoffload`.
- Developed and tested on a Moto Edge 30 Fusion (LineageOS 24, Android 17, APatch); also reported working on a Samsung Galaxy Tab S9 (Android 15, One UI 7, KernelSU Next). Both used the Hybrid Mount metamodule. Other devices are untested. See `docs/COMPATIBILITY.md`.
- Known limits: sound cuts for a second or two at every rate switch; the first moments of a track play at the old rate before the switch; not bit-perfect while sound effects, DRC or a software volume drop are active.
- Derived from an earlier GPL-3.0 module by varunpilankar and modified; see `NOTICE` for credits and licenses, and `docs/HISTORY.md` for the record of changes.
