# Auto Samplerate Changer for Android: module usage (v0.7.1, beta)

Flash `Auto-Samplerate-Changer-<version>.zip` in Magisk, APatch or KernelSU, **reboot**, then use a root shell (Termux: `su`).

Tested with APatch (Moto Edge 30 Fusion, Android 17) and KernelSU Next (Galaxy Tab S9, Android 15), both with the Hybrid Mount metamodule, and with Magisk (LG V30, LineageOS 22.2 / Android 15, USB DAC in `safest` mode; the 3.5 mm jack is not supported). On KernelSU/APatch your mount metamodule is what makes the `bp*` commands appear in `/system/bin`.

| Command | Purpose |
|---|---|
| `bpstatus` / `bpstatus -w` | one-line status: mixer rate/bit depth/kbps, source rate/format, gain, rate-matched or RESAMPLED; second line lists enabled effects |
| `bpcheck` | status plus DAC capabilities, ALSA `hw_params`, AudioFlinger USB threads, track table, volume |
| `bprate` / `bprate status` | show configured rate, auto-follow, boot apply, pause, DRC |
| `bprate 44100\|48000\|88200\|96000\|176400\|192000\|352800\|384000 [force]` | set the mixer rate (checks the DAC lists it; restarts audioserver) |
| `bprate auto on\|off` | enable/disable follow-the-track daemon |
| `bprate mode usb-only` | least invasive mode: only the USB audio policy file is changed, the main policy (speaker, headphones, Bluetooth) is left alone. Use it if sound disappears on another output with the default mode |
| `bprate pause on\|off\|<seconds>` | pause the player just before a rate switch and resume it after the audio server is back (default on, 1.5 s) |
| `bprate fast on\|off` | detect a new track's rate on the first poll and poll more often, so the pause comes sooner (more CPU use) |
| `bprate jack on\|off` | experimental: also follow the 3.5 mm jack when no USB DAC is used (needs a mode such as `bypass-offload`) |
| `bprate volsteps off\|<16-150>` | finer media volume steps, applied at boot (off by default; some ROMs ignore it) |
| `bprate extended on\|off` | let the jack be asked for 352.8/384 kHz (off by default; USB DACs use their own rate list) |
| `bprate profiles on\|off` / `bprate profile usb\|jack\|bt\|other <mode> [bits]` | experimental: a mode and bit depth per output (USB DAC, jack, Bluetooth, speaker/other); needs `bprate auto on` |
| `bprate deepbuffer keep\|trim` | keep or remove `deep_buffer` on USB routes |
| `bpverify` | why the overlay is or is not active (share this when reporting) |
| `bpreport` | **sanitized tester report** (run while playing) → `/sdcard/Download/bitperfect-report.txt` |
| `bpdiag` | environment/policy/AudioFlinger diagnostics → `/data/adb/usb_dac_bitperfect/bpdiag.txt` |
| `bpdump` | full AudioFlinger + policy dumps → `/sdcard/Download/af_full.txt` |
| `bpoffload on\|off\|status` | experiment: disable Qualcomm USB offload at next boot |

Before testing: set **media volume to maximum**, disable AudioFX/EQ/normalisation/crossfade, and read `docs/TESTING.md`.

If the installer says it found nothing to rewrite, it installs in *diagnostic mode* (system untouched); run `bpdiag`.
