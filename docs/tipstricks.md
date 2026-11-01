# Notes for Paperwhite 2

This port uses `/dev/rtc1` with `rtcwake` and has no Kindle-4-specific sleep-screen mode. See the [main README](../README.md) for tested behavior and limitations.

---

# Tips & tricks

## Producing dashboard images from a webpage

A common way to produce dashboard images for the Kindle is to take a screenshot of a website.
This can be done in a variety of ways. A few things to keep in mind are:

1. The images should be grayscale PNG images, without any alpha layers.
2. The resolution should match the display resolution of the Kindle. For the Paperwhite 2 use 758 × 1024 pixels in portrait (or 1024 × 758 landscape).

I personally use a headless Chrome instance with [Puppeteer](https://pptr.dev/).
The code I use can be found [here](./screenshotter/screenshot.js) as a reference.
