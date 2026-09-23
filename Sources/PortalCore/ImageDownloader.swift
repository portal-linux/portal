import Foundation

public enum ImageDownloaderError: Error {
    case hashMismatch(file: String)
    case signatureInvalid
    case decompressionFailed
}

public struct ImageDownloader {
    public let store: ImageStore
    public let publicKey: String

    public init(store: ImageStore, publicKey: String) {
        self.store = store
        self.publicKey = publicKey
    }

    // fetching over the network and shelling out to zstd for decompression are
    // exercised against a real release, not in unit tests - the cache-path and
    // verification logic they call into is what's covered by ImageStoreTests
    // and ImageVerifierTests.
    public func fetch(entry: ImageManifestEntry) async throws -> ImageCachePaths {
        let paths = store.paths(name: entry.name, version: entry.version)

        if store.isCached(name: entry.name, version: entry.version) {
            return paths
        }

        try FileManager.default.createDirectory(at: paths.root, withIntermediateDirectories: true)

        let compressedImage = paths.root.appendingPathComponent("disk.img.zst")
        try await download(from: entry.imageURL, to: compressedImage)
        try await download(from: entry.imageSignatureURL, to: paths.imageSignature)
        try await download(from: entry.kernelURL, to: paths.kernel)
        try await download(from: entry.initrdURL, to: paths.initrd)

        guard try ImageVerifier.verifySHA256(fileURL: compressedImage, expectedHex: entry.imageSHA256) else {
            throw ImageDownloaderError.hashMismatch(file: "disk.img.zst")
        }
        guard try ImageVerifier.verifySHA256(fileURL: paths.kernel, expectedHex: entry.kernelSHA256) else {
            throw ImageDownloaderError.hashMismatch(file: "kernel")
        }
        guard try ImageVerifier.verifySHA256(fileURL: paths.initrd, expectedHex: entry.initrdSHA256) else {
            throw ImageDownloaderError.hashMismatch(file: "initrd")
        }
        guard try ImageVerifier.verifyMinisignSignature(
            fileURL: compressedImage, signatureFileURL: paths.imageSignature, publicKey: publicKey
        ) else {
            throw ImageDownloaderError.signatureInvalid
        }

        try decompress(compressedImage, to: paths.image)
        try FileManager.default.removeItem(at: compressedImage)

        return paths
    }

    private func download(from url: URL, to destination: URL) async throws {
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)
    }

    private func decompress(_ source: URL, to destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["zstd", "-d", "-f", source.path, "-o", destination.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw ImageDownloaderError.decompressionFailed
        }
    }
}
