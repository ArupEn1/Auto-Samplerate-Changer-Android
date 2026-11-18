# Compatibility matrix

Results are marked as either backed by captured diagnostic output or reported by the maintainer. "Untested" means untested, not "unsupported".

| Device | ROM / Android | Root | DAC | App | Result |
|---|---|---|---|---|---|
| Moto Edge 30 Fusion (`tundra`) | LineageOS 24 / Android 17 | APatch + Hybrid Mount metamodule | USB DAC | Apple Music | Reported working by the maintainer: `bpstatus` showed `rate-matched` on a 96 kHz track, no replug needed; auto-follow switched the mixer 44.1 -> 96 kHz (follow log captured). |
| Samsung Galaxy Tab S9 | One UI 7 / Android 15 | KernelSU Next + Hybrid Mount metamodule | USB DAC | not stated | Reported working by the maintainer; no diagnostic output captured yet. |
| LG V30+ (H930DS, `joan`) | LineageOS 22.2 / Android 15 (LG Oreo vendor files) | Magisk | TEC USB DAC (TRN BlackPearl) | not stated | **Works in `safest` mode: rate-matched on USB, speaker still works.** The default mode (`bypass-offload-safer`) and `bypass-offload` replaced the whole audio policy and silenced the speaker; `usb-only` applied but music stayed on the 48 kHz deep-buffer path (resampled). **3.5 mm jack:** in `safest` it stays at 48 kHz / 16-bit, so it stays resampled there. In `bypass-offload` the jack does follow a rate set by hand (see [3.5 mm jack (experimental)](#35-mm-jack-experimental)). The V30's quad DAC itself supports 384 kHz / 32-bit, and the policy has a `direct_pcm` output for it, but only apps that request direct playback can use it (untested). LG's own Hi-Fi DAC settings are not part of LineageOS, so this may differ on stock firmware (untested). The "Volume listener for Music" effect shown is a stock vendor effect. |
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
- [Compatible Magisk-mirroring](https://github.com/Magisk-Modules-Alt-Repo/compatible-magisk-mirroring) is needed first on APatch, and on the latest Magisk (the unlocker's installer asks for it; installing the module fixed it on the LG V30+): the unlocker's installer stops with "no magisk-mirrors" without it. Install it, reboot, then install the unlocker.

| Device | ROM / Android | Root | DAC | Result |
|---|---|---|---|---|
| Moto Edge 30 Fusion (`tundra`) | LineageOS 24 / Android 17 | APatch + Hybrid Mount metamodule | TRN BlackPearl ("TEC USB DAC") | Before: a 192 kHz track was `RESAMPLED 192 kHz->96 kHz` in `bypass-offload-safer` (report captured). After installing Compatible Magisk-mirroring, rebooting and installing the unlocker: 192 kHz works, reported by the maintainer. After installing, Auto-follow had to be turned off and on once. |

## Not supported: AIDL-only audio HAL
**AIDL devices are not supported for now**, for example the Samsung Galaxy Z Fold8. These phones serve their audio policy from the AIDL audio HAL instead of a policy file. `dumpsys media.audio_policy` then prints `Config source: AIDL HAL` (a working phone prints a file path). This is a current limitation of the bundled backend, zyhk's [USB_SampleRate_Changer](https://github.com/yzyhk904/USB_SampleRate_Changer), which works by editing that policy file. On these phones there is no file to edit, so it stops with "Recent AIDL only devices are not supported!", and the module disables auto-follow. This depends on the ROM and its audio stack, not on the phone's age or Android version: the Moto above runs Android 17 and works.

| Device | ROM / Android | Root | Result |
|---|---|---|---|
| Samsung Galaxy Z Fold8 | One UI 9 / Android 17 | KernelSU | Not supported for now: `Config source: AIDL HAL`, backend error above (reported in issue #1) |

This is a limit of the backend. The backend's author is looking into AIDL devices, but there is no fix yet and no promise of one; if upstream gets it working, it can be merged into this module. For now these phones stay unsupported. Tracked upstream: [USB_SampleRate_Changer#44](https://github.com/yzyhk904/USB_SampleRate_Changer/issues/44) and [#42](https://github.com/yzyhk904/USB_SampleRate_Changer/issues/42). To check your phone: `su -c "dumpsys media.audio_policy | grep -i -A2 'config source'"`.

## 3.5 mm jack (experimental)
The jack can follow a rate in modes that change the internal outputs. Tested by hand, and then with automatic per-track following on the LG V30+.

| Device | ROM / Android | Root | Mode | Rate set by hand | Headset output thread (`dumpsys media.audio_flinger`) | Kernel stream (`hw_params`) |
|---|---|---|---|---|---|---|
| LG V30+ (H930DS) | LineageOS 22.2 / Android 15 | Magisk | `bypass-offload`, headphones on the jack, no DAC | 96 kHz | `AUDIO_DEVICE_OUT_WIRED_HEADSET`, 96000 Hz, 32-bit | `card0/pcm0p/sub0`: 96000 Hz, S24_3LE, 2 ch |
| same | same | same | same | 44.1 kHz | 44100 Hz, 32-bit | 44100 Hz, S24_3LE, 2 ch |
| same | same | same | same, set by hand (`bprate 384000`) | 384 kHz | `AUDIO_DEVICE_OUT_WIRED_HEADPHONE`, 384000 Hz, 32-bit | `card0/pcm0p/sub0`: 384000 Hz, S24_3LE, 2 ch, period 15360 |
| same | same | same | same, automatic (`bprate jack on`) | 192 kHz (track) | `AUDIO_DEVICE_OUT_WIRED_HEADPHONE`, 192000 Hz, 32-bit | `card0/pcm0p/sub0`: 192000 Hz, S24_3LE, 2 ch |

- The speaker thread moved to the same rate, as the backend's README says for this mode. Sound on the headphones was normal.
- The 32-bit mixer reaches the hardware as 24-bit. Whether the DAC chip processes the signal further is not known.
- On Qualcomm phones the speaker and the jack usually share one playback stream, so the stream alone does not prove which one is playing; the active output thread does.
- Automatic following: the follow log showed switches to 44.1, 48 and 192 kHz as tracks changed. Headphones without a microphone are listed as `WIRED_HEADPHONE`, a headset with one as `WIRED_HEADSET`; both are detected.
- Above 192 kHz: VLC played a 384 kHz file at 192 kHz. With Poweramp set to 352.8 kHz the follower picked 176.4 kHz (it halves rates above 192 kHz once). Not checked whether 176.4 kHz reached the hardware. Rates above 192 kHz are not a goal of the jack follower.
- Not tested yet: other phones and other modes.

## Per-output profiles (experimental)
Output detection (`out_kind`) reads `dumpsys media.audio_policy`: a wired headset or headphone in the "Available output devices" list means jack, a USB audio card in `/proc/asound` means USB DAC, otherwise other. Tests use the V30+'s plugged dump and the same dump without the headset entry. On the LG V30+ (jack = `bypass-offload`, other = `safest`) plugging in headphones switched to the jack profile and unplugging switched back, each in about 5 seconds including a 2.5 s audio server restart, and the speaker worked afterwards. The USB DAC profile is not tried on a phone yet.

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
