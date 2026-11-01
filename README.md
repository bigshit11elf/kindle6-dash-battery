# kindle6-dash-battery

**Home Assistant E-Ink dashboard client for the Kindle Paperwhite 2 (PW2, 6th-generation Kindle, 2013).**

A Paperwhite-2 adaptation of [bigshit11elf/kindle-dash-battery](https://github.com/bigshit11elf/kindle-dash-battery), derived from [pascalw/kindle-dash](https://github.com/pascalw/kindle-dash). The original targets a **Kindle 4 Non-Touch**, whereas this repository targets the **Kindle Paperwhite 2**. [MIT license](LICENSE); upstream copyright notice is retained.

**Target repository:** https://github.com/bigshit11elf/kindle6-dash-battery

## Features

- Download a pre-rendered PNG (e.g. from [hass-eink-dashboard](https://github.com/cryptomilk/hass-eink-dashboard)) and show it with Kindle `eips`.
- Optionally send the percentage from `gasgauge-info -c` to a Home Assistant webhook as JSON `{"battery": 84}`.
- Wake using `rtcwake -d /dev/rtc1 -m mem -s N`, not the Kindle-4 RTC path.
- Keep the **dashboard visible** while sleeping, even across long intervals.
- Disable Paperwhite 2 **frontlight** with `powerd flIntensity=0` and the PW2 sysfs interface, on startup and around every update/wakeup.
- **Continuous** log rotation while running (default two ~256 KiB files, `logs/dash.log` and `logs/dash.log.1`).
- Full or partial screen refresh; configurable cron-style schedule.
- Optional KUAL launcher extension under `KUAL/kindle6-dash-battery/`.

### PW2-specific changes versus Kindle 4

| Topic | Kindle 4 original | Paperwhite 2 here |
|---|---|---|
| RTC | `mxc_rtc.0/wakeup_enable` | `rtcwake` with `/dev/rtc1` |
| UI | K4 framework stop | `initctl stop framework`, `lab126_gui`, `webreader` (firmware-dependent) |
| Frontlight | None | PW2 `fl_tps6116x/.../fl_intensity` set to 0 |
| Logs | Append indefinitely | Continuous rotating pipe consumer |
| Sleep image | Optional `sleeping.png` | Remain on latest dashboard |
| Battery | Optional Home Assistant webhook in prior fork | Preserved |

## Requirements

- Jailbroken **Kindle Paperwhite 2** (6th Kindle generation). This is **not** an install guide for other Paperwhite generations.
- Working SSH (USBNetwork or Wi-Fi), Wi-Fi connectivity, and a configured PNG endpoint.
- Kindle commands `/usr/sbin/eips`, `gasgauge-info`, `lipc-set-prop`, `initctl`, `rtcwake` and a working wake-capable `/dev/rtc1`.
- **Two compiled Kindle ARM binaries**: `next-wakeup` and `xh`. They are not in the Git source archive.

### Source archive vs installable release

**GitHub's automatic "Download ZIP" is source code, not a ready-to-install Kindle package.** The binaries `xh` and `next-wakeup` are intentionally absent; see [Building](#building). You can reuse compatible copies from an existing installation if you have verified they work on your PW2. `make tarball` requires a Rust cross compilation setup (Docker/cross), produces a package and does not magically include binaries from this source ZIP.

## Install / upgrade

1. **Back up your existing dashboard directory**, especially `local/env.sh`, secret webhook settings, and scripts. Stop the existing dashboard process first.
2. Copy the built `dist/` contents (not the entire repository) into `/mnt/us/dashboard/`, keeping `xh` and `next-wakeup` executable. For an existing installation with known-working binaries you can copy the changed scripts from `src/` instead.
3. Configure `local/env.sh` or make a **local-only** `local/env.private.sh` based on `local/env.private.example.sh`. Never publish secrets or a real webhook ID.
4. Make the scripts executable: `chmod +x /mnt/us/dashboard/*.sh /mnt/us/dashboard/local/*.sh`.
5. Start over SSH: `/bin/sh /mnt/us/dashboard/start.sh`.

Sample upload from your **computer**, when your Kindle supports legacy SCP:

```sh
scp -O src/dash.sh src/start.sh src/stop.sh src/light-off.sh src/log-writer.sh src/wait-for-wifi.sh root@KINDLE_IP:/mnt/us/dashboard/
scp -O src/local/fetch-dashboard.sh src/local/env.sh root@KINDLE_IP:/mnt/us/dashboard/local/
```

**Do not overwrite an existing `local/env.sh` with your secrets without backing it up.** For a fresh installation, copy the complete compiled release and create your private configuration on the device.

### Home Assistant config

Example `/mnt/us/dashboard/local/env.private.sh`:

```sh
export DASHBOARD_URL="http://HOME_ASSISTANT_IP:8123/api/eink_dashboard/ENTRY_ID/image.png"
export BATTERY_WEBHOOK_URL="http://HOME_ASSISTANT_IP:8123/api/webhook/SECRET_WEBHOOK_ID"
```

The URL must return an E-Ink-compatible PNG, e.g. **758 × 1024** pixels in portrait. A regular Home Assistant HTML dashboard URL will not work. For the battery automation and JSON payload see [docs/home-assistant-battery.md](docs/home-assistant-battery.md).

### Start, stop, diagnostics

```sh
/bin/sh /mnt/us/dashboard/start.sh
# Inspect current and rotated logs:
tail -n 40 /mnt/us/dashboard/logs/dash.log
# Troubleshoot without suspend (WARNING: init still stops the Kindle UI):
DEBUG=true /bin/sh /mnt/us/dashboard/start.sh
# Terminate dashboard:
/bin/sh /mnt/us/dashboard/stop.sh
```

For a library launcher: installing `.sh` inside `documents/` does **not** by itself make it tappable. Use a compatible KUAL installation or supported Scriptlets launcher and ensure the dashboard process survives the shutdown of the Kindle GUI. KUAL is optional, not bundled as an installable Kindle extension package.

### RTC and light behavior

`rtcwake -d /dev/rtc1 -m mem -s N` was reported to work on the tested PW2 after the previous direct `wakealarm` + `echo mem` implementation intermittently missed wakeups. If `rtcwake` is missing or `/dev/rtc1` differs, do not substitute device IDs blindly. The frontlight script sets the intensity to zero at several points. **A short flash early in the wakeup process remains possible and is not proven fixed** because userspace code cannot run until the kernel resumes.

### Continuous log rotation

`start.sh` pipes `dash.sh` output through `log-writer.sh`. Every received log line is written into the current file, with a size check that triggers rotation while the dashboard continues. `MAX_LOG_BYTES` controls the default **262144 bytes** per file. Only the current and one previous file are retained. Very long individual lines can exceed the size cap slightly. Avoid starting concurrent dashboard instances; the log writer is not designed for concurrent writers.

### Limitations

- Scripts are a reference port for the tested PW2; firmware and jailbreak variants may behave differently.
- Frontlight might momentarily light during kernel resume even when userspace immediately resets it.
- Stopping `framework`/`lab126_gui` disables the normal UI. Recovery may require SSH access or reboot.
- `/mnt/us` file errors (`Input/output error`) are storage issues, not necessarily a dashboard bug.
- The battery webhook reports an HTTP request success, not necessarily Home Assistant automation success.

## Building

The supplied [Makefile](Makefile) compiles `src/next-wakeup` and a compatible `xh` for `arm-unknown-linux-musleabi` through Rust `cross`/Docker. On a Linux machine with `make`, Rust, Docker, and `cross` installed:

```sh
make tarball
```

The artifact is named `kindle6-dash-battery-<version>.tgz`. No precompiled executables or releases are included in the source ZIP.

## Acknowledgements and license

MIT licensed; see [LICENSE](LICENSE). Original copyright © 2021 Pascal Widdershoven, preserved as required. This port is based on [bigshit11elf/kindle-dash-battery](https://github.com/bigshit11elf/kindle-dash-battery) and [pascalw/kindle-dash](https://github.com/pascalw/kindle-dash). The `xh` and other components have their own upstream licenses; follow them when distributing compiled release binaries.
