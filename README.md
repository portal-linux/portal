# Portal

An open-source engine that runs any Linux distro on any Mac, on day one of every new Mac, with a native-feeling desktop experience.

Portal is built on Apple's Virtualization.framework and targets Apple Silicon Macs (M1 through M4 and later) running macOS 14 or newer.

## What is in this repo

- PortalCore: VM lifecycle, device configuration, and vsock RPC. Pure, testable logic lives here.
- PortalCLI: the `portal` command line tool.
- PortalApp: the SwiftUI + AppKit host application (source only in this repo).

## Building

The library and CLI build and test with the Swift toolchain:

```
swift build
swift test
```

Building the full macOS app bundle (PortalApp as a signed, entitled `.app`) requires Xcode 16 or newer. This is a manual step: the Virtualization entitlement in `portal.entitlements` must be applied and the bundle code-signed, neither of which the command line toolchain can do. The PortalApp sources compile with `swift build`, but they are not packaged into a runnable app here.

## CLI commands

```
portal create <name>     create a new vm from a distro image
portal start <name>      start an existing vm
portal stop <name>       stop a running vm
portal shell <name>      open a shell into a running vm over vsock
portal snapshot <name>   take a snapshot of a vm
```

## Non-goals

- Portal does not write a kernel or hardware drivers.
- Portal does not compete with Asahi Linux. It integrates with Asahi's work where it makes sense and never forks it.

## License

Apache License 2.0. See LICENSE.
