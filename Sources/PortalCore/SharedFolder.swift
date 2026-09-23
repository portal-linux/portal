import Foundation

public enum SharedFolderError: Error, Equatable {
    case emptyTag
    case hostPathNotFound
}

public struct SharedFolder: Equatable {
    public let tag: String
    public let hostPath: String

    public init(tag: String, hostPath: String) throws {
        guard !tag.isEmpty else {
            throw SharedFolderError.emptyTag
        }
        guard FileManager.default.fileExists(atPath: hostPath) else {
            throw SharedFolderError.hostPathNotFound
        }

        self.tag = tag
        self.hostPath = hostPath
    }
}
