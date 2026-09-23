import Foundation
import Testing
@testable import PortalCore

struct VMManifestTests {
    @Test func roundTripsThroughJSON() throws {
        let manifest = VMManifest(
            name: "arch",
            cpuCount: 4,
            memoryBytes: 4 * 1024 * 1024 * 1024,
            commandLine: "console=hvc0 root=/dev/vda rw",
            kernelPath: "/tmp/portal-vms/arch/kernel",
            initialRamdiskPath: "/tmp/portal-vms/arch/initrd",
            diskImagePath: "/tmp/portal-vms/arch/disk.img"
        )

        let data = try JSONEncoder().encode(manifest)
        let decoded = try JSONDecoder().decode(VMManifest.self, from: data)

        #expect(decoded == manifest)
    }

    @Test func initialRamdiskPathIsOptional() throws {
        let manifest = VMManifest(
            name: "arch",
            cpuCount: 4,
            memoryBytes: 4 * 1024 * 1024 * 1024,
            commandLine: "console=hvc0 root=/dev/vda rw",
            kernelPath: "/tmp/portal-vms/arch/kernel",
            initialRamdiskPath: nil,
            diskImagePath: "/tmp/portal-vms/arch/disk.img"
        )

        let data = try JSONEncoder().encode(manifest)
        let decoded = try JSONDecoder().decode(VMManifest.self, from: data)

        #expect(decoded.initialRamdiskPath == nil)
    }
}
