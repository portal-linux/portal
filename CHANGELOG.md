# Changelog

All notable changes to this project are documented here.

## [Unreleased]

- scaffold portal swift app and cli
- implement vm boot: config, runner, and create/start cli wiring
- add virtiofs shared folder support to vm boot and cli
- add rosetta directory share for x86_64 binaries in guest
- add virtio graphics device and windowed vm view via vzvirtualmachineview
- add usb keyboard and pointing device so gui window can receive input
- add curated image manifest, verifier, cache store, and downloader
- add portal create --image to fetch curated signed images
- point curated image manifest at develop now that portal-images is merged
- fix: portal app opens the vm named on the command line, not a hardcoded arch
- add script to package portalapp as a signed .app bundle
- gui: replace framebuffer console with a swiftterm-backed serial terminal
