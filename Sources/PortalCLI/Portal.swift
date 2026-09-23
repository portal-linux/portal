import ArgumentParser
import Darwin
import Foundation
import PortalCore
import Virtualization

nonisolated(unsafe) private var originalTermiosForRestore: termios?

private func restoreTerminalAndExit(_ signalNumber: Int32) {
    if var original = originalTermiosForRestore {
        tcsetattr(STDIN_FILENO, TCSANOW, &original)
    }
    exit(128 + signalNumber)
}

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

func imagesBaseDirectory() -> URL {
    FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Portal/images", isDirectory: true)
}

// ArgumentParser's ParsableCommand.run() is synchronous; this bridges a single
// async operation into it without retrofitting the whole command tree onto
// AsyncParsableCommand, matching the run-to-completion shape a one-shot CLI
// invocation actually needs.
func runBlocking<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) throws -> T {
    let semaphore = DispatchSemaphore(value: 0)
    nonisolated(unsafe) var result: Result<T, Error>!
    Task {
        do {
            result = .success(try await operation())
        } catch {
            result = .failure(error)
        }
        semaphore.signal()
    }
    semaphore.wait()
    return try result.get()
}

extension Portal {
    struct Create: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "create a new vm from a kernel, initrd and disk image."
        )

        @Argument(help: "name of the vm to create.")
        var name: String

        @Option(help: "curated image name to download and use, e.g. arch-spin. mutually exclusive with --kernel/--disk.")
        var image: String?

        @Option(help: "path to the linux kernel image.")
        var kernel: String?

        @Option(help: "path to the initial ramdisk (optional).")
        var initrd: String?

        @Option(help: "path to the ext4 root disk image.")
        var disk: String?

        @Option(help: "number of vCPUs.")
        var cpu: Int = 4

        @Option(name: .customLong("memory-gb"), help: "memory in GB.")
        var memoryGB: Int = 4

        @Option(help: "kernel command line.")
        var commandLine: String = "console=hvc0 root=/dev/vda rw rootwait"

        static func validateSource(image: String?, kernel: String?, disk: String?) throws {
            if image != nil && (kernel != nil || disk != nil) {
                throw ValidationError("pass either --image or --kernel/--disk, not both")
            }
            if image == nil && (kernel == nil || disk == nil) {
                throw ValidationError("pass --image <curated-name>, or both --kernel and --disk")
            }
        }

        func run() throws {
            try Self.validateSource(image: image, kernel: kernel, disk: disk)

            let store = vmStore()
            let paths = store.paths(for: name)
            try FileManager.default.createDirectory(at: paths.root, withIntermediateDirectories: true)

            let manifest: VMManifest
            if let image {
                manifest = try createFromCuratedImage(image, paths: paths)
            } else {
                manifest = try createFromManualPaths(paths: paths)
            }

            let data = try JSONEncoder().encode(manifest)
            try data.write(to: paths.manifest)

            print("created \(name) at \(paths.root.path)")
        }

        private func createFromManualPaths(paths: VMPaths) throws -> VMManifest {
            let fm = FileManager.default
            for path in [kernel!, disk!] {
                guard fm.fileExists(atPath: path) else {
                    throw ValidationError("no such file: \(path)")
                }
            }
            if let initrd, !fm.fileExists(atPath: initrd) {
                throw ValidationError("no such file: \(initrd)")
            }

            return VMManifest(
                name: name,
                cpuCount: cpu,
                memoryBytes: UInt64(memoryGB) * 1024 * 1024 * 1024,
                commandLine: commandLine,
                kernelPath: kernel!,
                initialRamdiskPath: initrd,
                diskImagePath: disk!
            )
        }

        private func createFromCuratedImage(_ imageName: String, paths: VMPaths) throws -> VMManifest {
            let cachePaths = try runBlocking {
                let (manifestData, _) = try await URLSession.shared.data(from: PortalImagesTrust.manifestURL)
                let manifest = try JSONDecoder().decode(ImageManifest.self, from: manifestData)
                guard let entry = manifest.entry(named: imageName) else {
                    throw ValidationError("no curated image named \(imageName)")
                }

                let store = ImageStore(baseDirectory: imagesBaseDirectory())
                let downloader = ImageDownloader(store: store, publicKey: PortalImagesTrust.publicKey)
                return try await downloader.fetch(entry: entry)
            }

            return VMManifest(
                name: name,
                cpuCount: cpu,
                memoryBytes: UInt64(memoryGB) * 1024 * 1024 * 1024,
                commandLine: commandLine,
                kernelPath: cachePaths.kernel.path,
                initialRamdiskPath: cachePaths.initrd.path,
                diskImagePath: cachePaths.image.path
            )
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

            var original = termios()
            tcgetattr(STDIN_FILENO, &original)
            originalTermiosForRestore = original
            var raw = RawTerminalMode.makeRaw(from: original)
            tcsetattr(STDIN_FILENO, TCSANOW, &raw)
            signal(SIGTERM, restoreTerminalAndExit)
            signal(SIGHUP, restoreTerminalAndExit)
            defer {
                var restore = original
                tcsetattr(STDIN_FILENO, TCSANOW, &restore)
            }

            print("console attached (ctrl-c goes to the guest; poweroff the guest to exit, or ctrl-c this process from another terminal)")

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
