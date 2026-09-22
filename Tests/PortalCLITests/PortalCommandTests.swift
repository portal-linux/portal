import Testing
import ArgumentParser
@testable import PortalCLI

struct PortalCommandTests {
    @Test func createParsesName() throws {
        let parsed = try Portal.parseAsRoot(["create", "arch"])
        let create = try #require(parsed as? Portal.Create)
        #expect(create.name == "arch")
    }

    @Test func startParsesName() throws {
        let parsed = try Portal.parseAsRoot(["start", "ubuntu"])
        let start = try #require(parsed as? Portal.Start)
        #expect(start.name == "ubuntu")
    }

    @Test func stopParsesName() throws {
        let parsed = try Portal.parseAsRoot(["stop", "fedora"])
        let stop = try #require(parsed as? Portal.Stop)
        #expect(stop.name == "fedora")
    }

    @Test func shellParsesName() throws {
        let parsed = try Portal.parseAsRoot(["shell", "debian"])
        let shell = try #require(parsed as? Portal.Shell)
        #expect(shell.name == "debian")
    }

    @Test func snapshotParsesName() throws {
        let parsed = try Portal.parseAsRoot(["snapshot", "arch"])
        let snapshot = try #require(parsed as? Portal.Snapshot)
        #expect(snapshot.name == "arch")
    }

    @Test func missingNameFails() {
        #expect(throws: (any Error).self) {
            _ = try Portal.parseAsRoot(["create"])
        }
    }

    @Test func unknownSubcommandFails() {
        #expect(throws: (any Error).self) {
            _ = try Portal.parseAsRoot(["teleport", "arch"])
        }
    }
}
