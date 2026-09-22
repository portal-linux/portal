import Testing
@testable import PortalCore

struct VMConfigurationTests {
    @Test func validConfigurationSucceeds() throws {
        let config = try VMConfiguration(
            cpuCount: 4,
            memoryBytes: 4 * 1024 * 1024 * 1024,
            diskImagePath: "/tmp/arch.img"
        )

        #expect(config.cpuCount == 4)
        #expect(config.memoryBytes == 4 * 1024 * 1024 * 1024)
        #expect(config.diskImagePath == "/tmp/arch.img")
    }

    @Test func zeroCPUCountIsRejected() {
        #expect(throws: VMConfigurationError.invalidCPUCount) {
            try VMConfiguration(
                cpuCount: 0,
                memoryBytes: 4 * 1024 * 1024 * 1024,
                diskImagePath: "/tmp/arch.img"
            )
        }
    }

    @Test func memoryBelowFloorIsRejected() {
        #expect(throws: VMConfigurationError.insufficientMemory) {
            try VMConfiguration(
                cpuCount: 2,
                memoryBytes: 256 * 1024 * 1024,
                diskImagePath: "/tmp/arch.img"
            )
        }
    }

    @Test func emptyDiskImagePathIsRejected() {
        #expect(throws: VMConfigurationError.missingDiskImagePath) {
            try VMConfiguration(
                cpuCount: 2,
                memoryBytes: 4 * 1024 * 1024 * 1024,
                diskImagePath: ""
            )
        }
    }

    @Test func memoryFloorIsExactlyAccepted() throws {
        let config = try VMConfiguration(
            cpuCount: 1,
            memoryBytes: VMConfiguration.minimumMemoryBytes,
            diskImagePath: "/tmp/arch.img"
        )

        #expect(config.memoryBytes == VMConfiguration.minimumMemoryBytes)
    }
}
