# Compatibility matrix

Results are marked as either backed by captured diagnostic output or reported by the maintainer. "Untested" means untested, not "unsupported".

| Device | ROM / Android | Root | DAC | App | Result |
|---|---|---|---|---|---|
| Moto Edge 30 Fusion (`tundra`) | LineageOS 24 / Android 17 | APatch + Hybrid Mount metamodule | USB DAC | Apple Music | Reported working by the maintainer: `bpstatus` showed `rate-matched` on a 96 kHz track, no replug needed; auto-follow switched the mixer 44.1 -> 96 kHz (follow log captured). |
| Samsung Galaxy Tab S9 | One UI 7 / Android 15 | KernelSU Next + Hybrid Mount metamodule | USB DAC | not stated | Reported working by the maintainer; no diagnostic output captured yet. |
| LG V30 (`joan`) | LineageOS 22.2 / Android 15 (LG Oreo vendor files) | Magisk | TEC USB DAC | not stated | **Works in `safest` mode: rate-matched on USB, speaker still works.** The default mode (`bypass-offload-safer`) and `bypass-offload` replaced the whole audio policy and silenced the speaker; `usb-only` applied but music stayed on the 48 kHz deep-buffer path (resampled). **3.5 mm jack: not supported**: its normal output is fixed at 48 kHz / 16-bit in the policy, so it stays resampled. The V30's quad DAC itself supports 384 kHz / 32-bit, and the policy has a `direct_pcm` output for it, but only apps that request direct playback can use it (untested). LG's own Hi-Fi DAC settings are not part of LineageOS, so this may differ on stock firmware (untested). The "Volume listener for Music" effect shown is a stock vendor effect. |
| OnePlus 7 (`guacamoleb`) | LineageOS 23.2 (2026-09-20) / Android 16 | Magisk | CrinEar Protocol Micro | Apple Music 24/96 | Baseline confirmed: music on a 384 kHz/32-bit mixer (resampled). Pin mechanism (v0.5) observed to create a 44.1 kHz/32-bit thread. **End-to-end bit-perfect: not achieved/confirmed.** Overlay missing in the v0.8 session. |
| same | same | Magisk | same | Spotify | Untested |
| Any other device | – | – | – | – | Untested |

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
