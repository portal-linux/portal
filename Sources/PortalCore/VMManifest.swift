import Foundation

public struct VMManifest: Codable, Equatable {
    public let name: String
    public let cpuCount: Int
    public let memoryBytes: UInt64
    public let commandLine: String
    public let kernelPath: String
    public let initialRamdiskPath: String?
    public let diskImagePath: String

    public init(
        name: String,
        cpuCount: Int,
        memoryBytes: UInt64,
        commandLine: String,
        kernelPath: String,
        initialRamdiskPath: String?,
        diskImagePath: String
    ) {
        self.name = name
        self.cpuCount = cpuCount
        self.memoryBytes = memoryBytes
        self.commandLine = commandLine
        self.kernelPath = kernelPath
        self.initialRamdiskPath = initialRamdiskPath
        self.diskImagePath = diskImagePath
    }
}
