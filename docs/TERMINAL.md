# Terminal commands

You do not need a terminal to use Auto Samplerate Changer: everything below is also available as buttons and switches in the module's **WebUI** (Status, Rate, Auto, Audio and Tools tabs). This page is for people who prefer a terminal (Termux: type `su` first) or who need the commands for scripting and bug reports. You need to run commands with su -c.

## Everyday commands

| Command | What it does |
|---|---|
| `bpstatus` | One line: mixer rate vs source rate, bit depth, digital gain and a `rate-matched` / `RESAMPLED` verdict. Second line lists enabled effects. |
| `bpstatus -w` | Same, refreshed live. |
| `bprate auto on` / `off` | Follow each track's sample rate automatically. **Auto-follow is off after installing, so turn this on first.** |
| `bprate <Hz>` | Set the mixer rate by hand (44100, 48000, 88200, 96000, 176400, 192000, 352800, 384000). Add `force` to apply a rate the DAC does not list. Restarts the audio server. |
| `bprate status` | Show the saved settings (rate, mode, auto-follow, boot apply, pause, DRC). |
| `bprate reset` | Remove the policy overlay and turn the automation off. |

## Settings

| Command | What it does |
|---|---|
| `bprate mode <name>` | Choose the backend mode: `bypass-offload-safer` (default), `bypass-offload`, `usb-only`, `safest`, `safest-auto`, `safe`, `legacy`, `offload`, `offload-safer`, `offload-direct`, `offload-hifi-playback`. |
| `bprate bits 16\|24\|32\|float` | Bit depth (32 is the default). |
| `bprate boot on\|off` | Re-apply the saved mode and rate at every boot. |
| `bprate pause on\|off\|<seconds>` | Pause the player just before a rate switch and resume afterwards (default on, 1.5 s). |
| `bprate fast on\|off` | Detect a new track's rate sooner (a bit more CPU use). |
| `bprate drc on\|off` | Compression: louder, but not bit-perfect. Off by default. |
| `bprate deepbuffer keep\|trim` | Keep or remove `deep_buffer` on USB routes. |

### Which mode?

- **Default (`bypass-offload-safer`):** try this first.
- **`safest`:** if the speaker or other outputs go silent with the default (this fixed an LG V30).
- **`usb-only`:** changes only the USB audio policy file and leaves the main policy alone; gentlest, but it did not stop resampling on the LG V30.
- The rest are for experiments. `bprate reset` undoes any mode.

## Diagnostics and reports

| Command | What it does |
|---|---|
| `bpverify` | Shows why the overlay is or is not active. Include this in bug reports. |
| `bpcheck` | Status plus DAC capabilities, ALSA view, USB threads, track table and volume. |
| `bpdiag` | Environment, policy and AudioFlinger diagnostics, written to `/data/adb/usb_dac_bitperfect/bpdiag.txt`. |
| `bpreport` | **Sanitized report** written to `/sdcard/Download/bitperfect-report.txt`. Run it while music is playing and review it before sharing. |
| `bpdump` | Full dumps for bug reports. |
| `bpoffload on\|off` | Experiment: disable Qualcomm USB offload at the next boot. |

Logs live in `/data/adb/usb_dac_bitperfect/` (for example `follow.log`).

## If the commands are not found

On KernelSU and APatch the `bp*` tools only appear in `/system/bin` when a mount metamodule (for example Hybrid Mount) is installed. The WebUI works either way.
