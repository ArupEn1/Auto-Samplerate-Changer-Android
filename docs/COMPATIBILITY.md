# Compatibility matrix

Results are marked as either backed by captured diagnostic output or reported by the maintainer. "Untested" means untested, not "unsupported".

| Device | ROM / Android | Root | DAC | App | Result |
|---|---|---|---|---|---|
| Moto Edge 30 Fusion (`tundra`) | LineageOS 24 / Android 17 | APatch + Hybrid Mount metamodule | USB DAC | Apple Music | Reported working by the maintainer: `bpstatus` showed `rate-matched` on a 96 kHz track, no replug needed; auto-follow switched the mixer 44.1 -> 96 kHz (follow log captured). |
| Samsung Galaxy Tab S9 | One UI 7 / Android 15 | KernelSU Next + Hybrid Mount metamodule | USB DAC | not stated | Reported working by the maintainer; no diagnostic output captured yet. |
| LG V30 (`joan`) | LineageOS 22.2 / Android 15 (LG Oreo vendor files) | Magisk | TEC USB DAC (TRN BlackPearl) | not stated | **Works in `safest` mode: rate-matched on USB, speaker still works.** The default mode (`bypass-offload-safer`) and `bypass-offload` replaced the whole audio policy and silenced the speaker; `usb-only` applied but music stayed on the 48 kHz deep-buffer path (resampled). **3.5 mm jack: not supported**: its normal output is fixed at 48 kHz / 16-bit in the policy, so it stays resampled. The V30's quad DAC itself supports 384 kHz / 32-bit, and the policy has a `direct_pcm` output for it, but only apps that request direct playback can use it (untested). LG's own Hi-Fi DAC settings are not part of LineageOS, so this may differ on stock firmware (untested). The "Volume listener for Music" effect shown is a stock vendor effect. |
| OnePlus 7 (`guacamoleb`) | LineageOS 23.2 (2026-09-20) / Android 16 | Magisk | CrinEar Protocol Micro | Apple Music 24/96 | Baseline confirmed: music on a 384 kHz/32-bit mixer (resampled). Pin mechanism (v0.5) observed to create a 44.1 kHz/32-bit thread. **End-to-end bit-perfect: not achieved/confirmed.** Overlay missing in the v0.8 session. |
| same | same | Magisk | same | Spotify | Untested |
| Any other device | – | – | – | – | Untested |

## DACs reported working
Reported by the maintainer unless stated otherwise. DAC support mostly comes from the bundled USB_SampleRate_Changer backend, which is widely used; the auto-follow part is newer and has been tried on fewer devices. Reports for other DACs are welcome.

| DAC | Result |
|---|---|
| TRN BlackPearl (shows up in Android as "TEC USB DAC") | Reported working by the maintainer; on the LG V30 it is rate-matched on USB in `safest` mode (see the table above) |
| FiiO BTA30 Pro (in USB DAC mode) | Reported working by the maintainer |
| More to come | Add yours via a *Compatibility report* issue |

## Rates above 96 kHz (USB driver lock)
On some phones the USB audio driver is locked to 96 kHz. The module still asks for the track's rate (for example 192 kHz), but Android keeps resampling to 96 kHz and the backend prints a "96kHz lock" warning (it is in the WebUI report). zyhk's separate modules lift the lock:

- [usb-samplerate-unlocker](https://github.com/Magisk-Modules-Alt-Repo/usb-samplerate-unlocker) removes the 96 kHz limit by patching the vendor USB audio libraries. Read its page first.
- [Compatible Magisk-mirroring](https://github.com/Magisk-Modules-Alt-Repo/compatible-magisk-mirroring) is needed first on APatch: the unlocker's installer stops with "no magisk-mirrors" without it. Install it, reboot, then install the unlocker.

| Device | ROM / Android | Root | DAC | Result |
|---|---|---|---|---|
| Moto Edge 30 Fusion (`tundra`) | LineageOS 24 / Android 17 | APatch + Hybrid Mount metamodule | TRN BlackPearl ("TEC USB DAC") | Before: a 192 kHz track was `RESAMPLED 192 kHz->96 kHz` in `bypass-offload-safer` (report captured). After installing Compatible Magisk-mirroring, rebooting and installing the unlocker: 192 kHz works, reported by the maintainer. After installing, Auto-follow had to be turned off and on once. |

## Legend
- **Confirmed rate-matched:** `bpstatus` showed `rate-matched`, `gain 0 dB`, no enabled effects while playing.
- **Partial:** pin observed, but one of the above missing.
- **Baseline only:** stock behaviour captured, module not (successfully) applied.

## What is device-specific
- The mix port name `hifi_playback` and USB-on-primary-HAL routing are Qualcomm/OnePlus vendor choices.
- AIDL-only audio HAL devices may expose the platform bit-perfect mixer behaviour; this module does not target them.
- Devices whose USB output is a static mix port may only need the v0.1-style rate rewrite (kept in `patch_policy`).

## Submit a result
Follow [TESTER_GUIDE.md](TESTER_GUIDE.md) and open a *Compatibility report* issue with the `bpreport` file (taken **while a track plays**).
