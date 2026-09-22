import ArgumentParser
import Foundation
import PortalCore
import Virtualization

@main
struct Portal: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "portal",
        abstract: "run linux distros on apple silicon macs.",
        subcommands: [Create.self, Start.self, Stop.self, Shell.self, Snapshot.self]
    )
}

func vmStore() -> VMStore {
    let base = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Portal/vms", isDirectory: true)
    return VMStore(baseDirectory: base)
}

extension Portal {
    struct Create: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "create a new vm from a kernel, initrd and disk image."
        )

        @Argument(help: "name of the vm to create.")
        var name: String

        @Option(help: "path to the linux kernel image.")
        var kernel: String

        @Option(help: "path to the initial ramdisk (optional).")
        var initrd: String?

        @Option(help: "path to the ext4 root disk image.")
        var disk: String

        @Option(help: "number of vCPUs.")
        var cpu: Int = 4

        @Option(name: .customLong("memory-gb"), help: "memory in GB.")
        var memoryGB: Int = 4

        @Option(help: "kernel command line.")
        var commandLine: String = "console=hvc0 root=/dev/vda rw rootwait"

        func run() throws {
            let fm = FileManager.default
            for path in [kernel, disk] {
                guard fm.fileExists(atPath: path) else {
                    throw ValidationError("no such file: \(path)")
                }
            }
            if let initrd, !fm.fileExists(atPath: initrd) {
                throw ValidationError("no such file: \(initrd)")
            }

            let store = vmStore()
            let paths = store.paths(for: name)
            try fm.createDirectory(at: paths.root, withIntermediateDirectories: true)

            let manifest = VMManifest(
                name: name,
                cpuCount: cpu,
                memoryBytes: UInt64(memoryGB) * 1024 * 1024 * 1024,
                commandLine: commandLine,
                kernelPath: kernel,
                initialRamdiskPath: initrd,
                diskImagePath: disk
            )

            let data = try JSONEncoder().encode(manifest)
            try data.write(to: paths.manifest)

            print("created \(name) at \(paths.root.path)")
        }
    }

    struct Start: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "start an existing vm."
        )

        @Argument(help: "name of the vm to start.")
        var name: String

        @Option(help: "host directory to share into the guest at /mnt/mac (pass an empty string to disable).")
        var share: String = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Portal/shared").path

        func run() throws {
            let store = vmStore()
            let paths = store.paths(for: name)

            guard FileManager.default.fileExists(atPath: paths.manifest.path) else {
                throw ValidationError("no vm named \(name), run 'portal create \(name)' first")
            }

            let data = try Data(contentsOf: paths.manifest)
            let manifest = try JSONDecoder().decode(VMManifest.self, from: data)

            let vmConfig = try VMConfiguration(
                cpuCount: manifest.cpuCount,
                memoryBytes: manifest.memoryBytes,
                diskImagePath: manifest.diskImagePath
            )

            let boot = BootImage(
                kernelURL: URL(fileURLWithPath: manifest.kernelPath),
                initialRamdiskURL: manifest.initialRamdiskPath.map { URL(fileURLWithPath: $0) },
                commandLine: manifest.commandLine
            )

            let sharedFolder = share.isEmpty ? nil : try SharedFolder(tag: "mac", hostPath: share)
            let rosettaAvailability: RosettaAvailability
            switch VZLinuxRosettaDirectoryShare.availability {
            case .notSupported: rosettaAvailability = .notSupported
            case .notInstalled: rosettaAvailability = .notInstalled
            case .installed: rosettaAvailability = .installed
            @unknown default: rosettaAvailability = .notSupported
            }
            let enableRosetta = RosettaSupport.shouldEnable(for: rosettaAvailability)
            if !enableRosetta {
                print("rosetta not available on this host (\(rosettaAvailability)), skipping x86_64 binary support")
            }

            let bootstrapper = VMBootstrapper(configuration: vmConfig)
            let vzConfig = try bootstrapper.makeVirtualMachineConfiguration(
                boot: boot,
                sharedFolder: sharedFolder,
                enableRosetta: enableRosetta
            )

            let runner = VMRunner()
            try runner.run(configuration: vzConfig)
        }
    }

    struct Stop: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "stop a running vm."
        )

        @Argument(help: "name of the vm to stop.")
        var name: String

        func run() throws {
            print("stop: \(name)")
        }
    }

    struct Shell: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "open a shell into a running vm over vsock."
        )

        @Argument(help: "name of the vm to open a shell into.")
        var name: String

        func run() throws {
            print("shell: \(name)")
        }
    }

    struct Snapshot: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "take a snapshot of a vm."
        )

        @Argument(help: "name of the vm to snapshot.")
        var name: String

        func run() throws {
            print("snapshot: \(name)")
        }
    }
}
