import Foundation
import Testing
@testable import PortalCore

struct ImageStoreTests {
    @Test func pathsAreNamespacedByNameAndVersion() {
        let store = ImageStore(baseDirectory: URL(fileURLWithPath: "/tmp/portal-images"))
        let paths = store.paths(name: "arch-spin", version: "5")

        #expect(paths.root.path == "/tmp/portal-images/arch-spin/5")
        #expect(paths.image.path == "/tmp/portal-images/arch-spin/5/disk.img")
        #expect(paths.imageSignature.path == "/tmp/portal-images/arch-spin/5/disk.img.minisig")
        #expect(paths.kernel.path == "/tmp/portal-images/arch-spin/5/kernel")
        #expect(paths.initrd.path == "/tmp/portal-images/arch-spin/5/initrd")
    }

    @Test func differentVersionsProduceDifferentRoots() {
        let store = ImageStore(baseDirectory: URL(fileURLWithPath: "/tmp/portal-images"))
        #expect(store.paths(name: "arch-spin", version: "1").root != store.paths(name: "arch-spin", version: "2").root)
    }

    @Test func isCachedIsFalseWhenFilesMissing() {
        let store = ImageStore(baseDirectory: URL(fileURLWithPath: "/tmp/portal-images-\(UUID().uuidString)"))
        #expect(store.isCached(name: "arch-spin", version: "1") == false)
    }

    @Test func isCachedIsTrueWhenAllFilesPresent() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ImageStore(baseDirectory: base)
        let paths = store.paths(name: "arch-spin", version: "1")
        try FileManager.default.createDirectory(at: paths.root, withIntermediateDirectories: true)
        for url in [paths.image, paths.imageSignature, paths.kernel, paths.initrd] {
            try Data().write(to: url)
        }
        defer { try? FileManager.default.removeItem(at: base) }

        #expect(store.isCached(name: "arch-spin", version: "1") == true)
    }
}
