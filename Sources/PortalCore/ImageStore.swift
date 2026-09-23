import Foundation

public struct ImageCachePaths: Equatable {
    public let root: URL
    public let image: URL
    public let imageSignature: URL
    public let kernel: URL
    public let initrd: URL
}

public struct ImageStore {
    public let baseDirectory: URL

    public init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
    }

    public func paths(name: String, version: String) -> ImageCachePaths {
        let root = baseDirectory
            .appendingPathComponent(name, isDirectory: true)
            .appendingPathComponent(version, isDirectory: true)
        return ImageCachePaths(
            root: root,
            image: root.appendingPathComponent("disk.img"),
            imageSignature: root.appendingPathComponent("disk.img.minisig"),
            kernel: root.appendingPathComponent("kernel"),
            initrd: root.appendingPathComponent("initrd")
        )
    }

    public func isCached(name: String, version: String) -> Bool {
        let paths = paths(name: name, version: version)
        let fm = FileManager.default
        return fm.fileExists(atPath: paths.image.path)
            && fm.fileExists(atPath: paths.imageSignature.path)
            && fm.fileExists(atPath: paths.kernel.path)
            && fm.fileExists(atPath: paths.initrd.path)
    }
}
