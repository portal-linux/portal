import Foundation

public enum VMConfigurationError: Error, Equatable {
    case invalidCPUCount
    case insufficientMemory
    case missingDiskImagePath
}

public struct VMConfiguration: Equatable, Sendable {
    public static let minimumMemoryBytes: UInt64 = 512 * 1024 * 1024

    public let cpuCount: Int
    public let memoryBytes: UInt64
    public let diskImagePath: String

    public init(cpuCount: Int, memoryBytes: UInt64, diskImagePath: String) throws {
        guard cpuCount >= 1 else {
            throw VMConfigurationError.invalidCPUCount
        }
        guard memoryBytes >= Self.minimumMemoryBytes else {
            throw VMConfigurationError.insufficientMemory
        }
        guard !diskImagePath.isEmpty else {
            throw VMConfigurationError.missingDiskImagePath
        }

        self.cpuCount = cpuCount
        self.memoryBytes = memoryBytes
        self.diskImagePath = diskImagePath
    }
}
