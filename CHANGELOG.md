# Changelog

## Unreleased — Kindle6 Dash Battery / PW2 port (2026-11-01)

- Target Kindle Paperwhite 2 (6th-generation Kindle, PW2) instead of Kindle 4 Non-Touch.
- Replace Kindle 4 RTC control with `rtcwake -d /dev/rtc1 -m mem -s SECONDS`.
- Stop GUI services to avoid overwriting the E-Ink dashboard.
- Keep the dashboard on screen across long sleep intervals (no `sleeping.png` switch).
- Switch the PW2 frontlight off at startup, on wake, and before/after refresh and suspend.
- Add continuous 256 KiB log rotation via `log-writer.sh` (one archived log).
- Retain Home Assistant PNG fetching and optional battery webhook reporting.
- Update KUAL extension name, documentation and build artifact naming.

### Known limitations

- RTC wakeup via `rtcwake` reported working on one PW2; not a fleet-wide guarantee.
- Brief frontlight illumination before the script resumes can still occur; cannot be guaranteed off during the earliest kernel wake phase.
- Scriptlet launcher / GUI-service shutdown behavior varies by Kindle firmware.
- Source checkout does not include compiled `xh` and `next-wakeup`; build or supply compatible binaries.

## Upstream and prior fork

Based on `bigshit11elf/kindle-dash-battery` and `pascalw/kindle-dash` (MIT licensed).
