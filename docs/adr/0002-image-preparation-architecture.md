# 2. Build guest disk images in CI, not on the host Mac

Date: 2026-09-22

## Status

Accepted

## Context

Early local dev testing prepared a bootable Arch Linux ARM disk image directly
on a macOS host: download the upstream rootfs tarball, extract it with `tar`,
and pack it into an ext4 image with `mkfs.ext4 -d`. This repeatedly broke in
ways specific to macOS as a build host, not to Portal's own code:

- macOS's default APFS volume is case-insensitive. Linux paths that differ
  only by case (`terminfo/P/P7` vs `terminfo/p/p7`) collide during extraction,
  corrupting the archive partway through.
- Extracting as a non-root user cannot preserve the original file ownership
  from the archive. Every file ends up owned by the host user instead of
  root, which trips systemd's own path-safety hardening (`Detected unsafe
  path transition`) and fails setuid binaries like `mount` that depend on
  being root-owned to function.
- `fakeroot` did not reliably intercept ownership syscalls for either macOS's
  system `tar`/`chown` (hardened-runtime binaries that drop `DYLD_*` env vars)
  or Homebrew's GNU `tar` on this machine, so it could not paper over the
  extraction problem either.
- Manually patching individual files' ownership after the fact with `debugfs`
  fixed specific symptoms (`sshd`, `mount`) but left the ext4 image with minor
  structural drift, which surfaced later as `Structure needs cleaning` errors
  under a full `pacman -Syyu` - an operation that stresses far more of the
  filesystem than basic boot/login/ssh testing ever did.

None of this is a Portal application bug. It is what happens when a genuine
Linux root filesystem is assembled with tools that were never designed to
preserve Linux ownership and case-sensitive paths - namely, tools running on
macOS. The `portal-images` GitHub Actions workflow was already building the
`arch-spin` ISO correctly, inside a real `archlinux` container on Linux,
untouched by any of these problems.

## Decision

Guest disk images are built and signed once, on real Linux, in
`portal-images`' CI - never assembled ad hoc on a contributor's or user's Mac.

- `portal-images` CI is extended to also produce a ready-to-boot, signed raw
  disk image (correct root ownership, no case-sensitivity risk, no manual
  patching) as a release artifact, alongside the existing installer ISO.
  Every image ships a SHA-256 hash and a minisign signature, per the existing
  signed-manifest design in the project plan.
- `portal create <name> --image <curated-name>` becomes the default,
  recommended path: download the signed image from a curated release,
  verify it, cache it locally, and boot it. No host-side image assembly.
- The existing `--kernel` / `--disk` / `--initrd` flags stay available for
  anyone who wants to point Portal at their own already-built image - this
  matches the project plan's own "import own ISO" scope. What changes is
  that Portal itself never tries to build a Linux root filesystem using
  macOS tools again.

The CLI-side download/verify/cache flow is scoped as follow-up work, tracked
separately from this decision. This ADR settles the architecture; it does not
claim the CLI integration is done.

## Consequences

- The class of bug this ADR describes (case-insensitive extraction, wrong
  ownership, fakeroot not intercepting syscalls, ext4 drift from manual
  patches) cannot recur for curated images, because no Mac ever runs `tar`,
  `mkfs.ext4`, or `debugfs` against a Linux rootfs again.
- `portal-images` CI takes on real, verifiable responsibility: its build
  output is the thing every user's `portal create` ultimately trusts and
  boots, so its signing and verification steps are load-bearing, not
  optional polish.
- Contributors testing locally on a Mac should build test images inside a
  real Linux environment (a container or VM), never directly against the
  host filesystem - this stops the same failure class from reappearing in
  someone's local dev loop even before the CLI download flow exists.
- Until the CLI download/verify flow ships, `portal create` still requires
  manually-prepared `--kernel`/`--disk` paths. That flow is real, scoped,
  follow-up work, not implied to exist by this decision.
