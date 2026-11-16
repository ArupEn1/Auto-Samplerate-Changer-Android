# Development history

Record of the changes made to the code this project is derived from (see `NOTICE`). The build numbers here (0.1.0 to 0.11.3) are internal development numbers from before the first release and are not release versions.

### 0.11.3
- WebUI: small yellow heads-up badges under the status pill when `bpstatus` reports enabled sound effects or a volume drop (`VOLUME -N dB`). Nothing is shown when the signal is untouched.

### 0.11.2
- Removed the status notification option (`bprate notify`, the WebUI switch and the `cmd notification` call in `bpfollow`): it was untested and could cause trouble. Updating clears the old flag and cancels any leftover notification.

### 0.11.1
- WebUI: "Save full report to Downloads" button (runs `bpreport`). `bpreport` now also includes the settings, follow log (last 60 lines), boot log and install log.

### 0.11.0
- **WebUI** (`module/webroot/index.html`): one page with Status, Rate, Auto, Audio and Tools tabs; toggles and buttons run the existing `bprate`/`bp*` commands through the KernelSU/APatch WebUI `ksu.exec` bridge. A simulated preview mode is used when the page is opened in a normal browser.
- `bprate state`: machine-readable `key=value` output used by the WebUI.

### 0.10.5
- New `bprate fast on|off` (default OFF): act on the first poll that sees a new rate (no confirmation poll), poll every ~0.12 s while playing and shorten the settle time after the pause. Aim: the pause lands well under a second after the track starts. Trade-off: more CPU while playing and a higher chance of switching on a short non-music sound.

### 0.10.4
- Auto-follow can pause the player just before it changes the mixer rate and resume it afterwards (`bprate pause on|off|<seconds>`, default ON, 1.5 s). It only acts when the rate actually changes. Uses `cmd media_session dispatch pause|play`, falling back to media key events.

### 0.10.3
- New `bprate drc on|off`: passes the backend's `--drc` option (Qualcomm dynamic range compression, typically louder; not bit-perfect). Default OFF. Added after A/B testing on a Moto Edge 30 Fusion: the DRC-less backend sounded slightly flatter and a little quieter than the stock offload path.
- The boot apply now goes through `apply_rate`, so it also honours the DRC setting.

### 0.10.2
- **Fix (the real cause of "auto-follow does nothing"):** inside init's mount namespace the backend was started as `nsenter -t 1 -m sh script --bypass-offload-safer ...`, and Android's `nsenter` tried to parse `--bypass-offload-safer` as its own option (`Unknown option 'bypass-offload-safer'`), so the backend never ran in v0.10.0/0.10.1. The arguments now travel in the environment through `sr_wrap.sh`; no dash-prefixed argument follows `nsenter`.
- Test: a fake `nsenter` that rejects dash-prefixed arguments after the command reproduces the failure and checks the fix.

### 0.10.1
- Fix: `bpfollow` ignored backend failures. A failed switch left the recorded rate unchanged, so it retried every ~1.5 s until the switch limit turned auto-follow off, with no error logged. It now logs the backend's output, backs off, and disables itself after two consecutive failures with the reason in `follow.log`.

### 0.10.0
- **Backend mode.** The module no longer patches the audio policy itself. It bundles zyhk's USB_SampleRate_Changer (AGPL-3.0, unmodified, in `module/usbsrc`, license included) and drives it: the script generates the policy from its templates, bind-mounts it and restarts audioserver.
  Reason: on a Moto Edge 30 Fusion (LineageOS 24 / Android 17) the old approach could not move music off the Qualcomm primary output (48 kHz / 16-bit); the backend has a mode that bypasses USB offload and uses the generic USB path.
- Default: `--bypass-offload-safer`, 44.1 kHz, 32-bit, applied at every boot (the bind mount does not survive a reboot). `bprate mode <name>`, `bprate bits <n>`, `bprate boot on|off`, `bprate reset`.
- The backend is run with a clean `PATH` and, when needed, inside init's mount namespace (`nsenter -t 1 -m`), so an APatch/Magisk/Termux shell does not change its behaviour.
- Per-track follow (`bprate auto on`) now calls the backend for each rate change; it starts OFF after an update.
- Removed: boot guard and policy-overlay installer (nothing is overlaid by the module any more), `bprate deepbuffer|primary`. The legacy policy patcher stays in `common.sh` unused.
- Tests: backend invocation (flags, rate, bits, failure handling) with a mock; presence of the bundled files.

### 0.9.3
- Fix: `orig.list` stored a path inside `modules_update`, which no longer exists after the install is finished, so `bprate`, `bprate deepbuffer` and the auto-follow daemon could not find the pristine policy and silently changed nothing. Pristine copies are now resolved inside the installed module directory.
- `patch_ok` also rejects empty files.
- New experiment `bprate primary keep|trim`: remove `primary output` from the USB routes. Found on a Moto Edge 30 Fusion (LineageOS 24 / Android 17): the pinned `hifi_playback` port existed and the overlay was live, but media still played on the primary output (48 kHz / 16-bit, FAST), so it was resampled 44.1 -> 48 kHz.
- `common.sh` state/module directories overridable (`BP_STATE`, `BP_MODDIR`) for tests; new tests for the primary trim and for pristine-copy resolution.

### 0.9.2
- Fix: `bpdiag` and `bpcheck` had literal `\n` instead of line breaks, so `bpdiag` never loaded `common.sh` or wrote its output file, and `bpcheck` skipped its AudioFlinger thread/track sections.
- Overlay `/odm/etc` and `/product/etc` policy files too (the audio policy loader prefers `/odm`, then `/vendor`, then `/system`); previously only `/vendor` and `/system` were patched.
- `bpdiag`, `bpverify` and the boot check read the policy file(s) actually patched, not only `/vendor/etc/audio_policy_configuration.xml`; `bpdiag` and `bpverify` list every policy file on the device.
- Installer message no longer says "built for Android 16" on newer Android.
- Test suite: lint check for broken literal `\n` line breaks in scripts.

### 0.9.1
- `bpreport`: sanitized tester report; `sanitize_report` helper (test added).
- Early-adopter documentation set: README rewrite, INSTALL, TESTER_GUIDE, FAQ; CI and pre-release workflows.

### 0.9.0
- Track-table parser rewritten against a real Android 16 dump (anchor on the `yes`/`no` Active token; handles blank `Type` and split `pid/ uid`).
- `bpstatus` reports gain (`G db`), enabled effects, source bit depth and kbps; flags `RESAMPLED`, `VOLUME`, float source.
- New `bpverify` (module/overlay/mount/policy diagnosis) and installer log.
- Offline test-suite (`tests/run.sh`, 28 checks) and fixtures.

### 0.8.0
- Installer no longer treats its own overlay as the pristine file; reuses saved pristine copies or a Magisk mirror; aborts instead of shipping an empty overlay on update.
- Boot guard disables only after 2 consecutive failed boots.
- `bpdump`; track table located via the "Tracks of which" line.

### 0.7.0
- Single `dumpsys` per poll, faster follow loop, wait-for-audioserver instead of fixed sleep, timing log.
- Bit depth and kbps in status; optional notification (untested).

### 0.6.0
- Remove `deep_buffer` from USB routes (`bprate deepbuffer keep|trim`); track tables in `bpcheck`/`bpdiag`.

### 0.5.0
- Pin the dynamic `hifi_playback` mix port to one static profile (first change observed to take effect on the reference device).
- `bpoffload`, USB thread info.

### 0.4.0 / 0.3.0 / 0.2.0 / 0.1.0
- Diagnostic installer and `bpdiag` (0.3), parser attempts (0.2, 0.4), auto-follow daemon (0.2), static USB mix-port rate rewrite with `bpcheck`/`bprate` (0.1).
