import Foundation

public struct VMPaths: Equatable {
    public let root: URL
    public let diskImage: URL
    public let kernel: URL
    public let initialRamdisk: URL
    public let manifest: URL
}

public struct VMStore {
    public let baseDirectory: URL

    public init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
    }

    public func paths(for name: String) -> VMPaths {
        let root = baseDirectory.appendingPathComponent(name, isDirectory: true)
        return VMPaths(
            root: root,
            diskImage: root.appendingPathComponent("disk.img"),
            kernel: root.appendingPathComponent("kernel"),
            initialRamdisk: root.appendingPathComponent("initrd"),
            manifest: root.appendingPathComponent("manifest.json")
        )
    }
}
