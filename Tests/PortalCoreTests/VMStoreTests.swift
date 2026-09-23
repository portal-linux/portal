import Foundation
import Testing
@testable import PortalCore

struct VMStoreTests {
    @Test func pathsAreNamespacedUnderVMDirectory() {
        let store = VMStore(baseDirectory: URL(fileURLWithPath: "/tmp/portal-vms"))
        let paths = store.paths(for: "arch")

        #expect(paths.root.path == "/tmp/portal-vms/arch")
        #expect(paths.diskImage.path == "/tmp/portal-vms/arch/disk.img")
        #expect(paths.kernel.path == "/tmp/portal-vms/arch/kernel")
        #expect(paths.initialRamdisk.path == "/tmp/portal-vms/arch/initrd")
        #expect(paths.manifest.path == "/tmp/portal-vms/arch/manifest.json")
    }

    @Test func differentNamesProduceDifferentRoots() {
        let store = VMStore(baseDirectory: URL(fileURLWithPath: "/tmp/portal-vms"))
        #expect(store.paths(for: "arch").root != store.paths(for: "fedora").root)
    }
}
