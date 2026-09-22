import ArgumentParser

@main
struct Portal: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "portal",
        abstract: "run linux distros on apple silicon macs.",
        subcommands: [Create.self, Start.self, Stop.self, Shell.self, Snapshot.self]
    )
}

extension Portal {
    struct Create: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "create a new vm from a distro image."
        )

        @Argument(help: "name of the vm to create.")
        var name: String

        func run() throws {
            print("create: \(name)")
        }
    }

    struct Start: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "start an existing vm."
        )

        @Argument(help: "name of the vm to start.")
        var name: String

        func run() throws {
            print("start: \(name)")
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
