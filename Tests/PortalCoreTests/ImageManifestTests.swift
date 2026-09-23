import Foundation
import Testing
@testable import PortalCore

struct ImageManifestTests {
    @Test func decodesRealManifestShape() throws {
        let json = """
        {
          "schema_version": 2,
          "images": [
            {
              "name": "arch-spin",
              "version": "1",
              "arch": "aarch64",
              "min_app_version": "0.1.0",
              "image_url": "https://example.com/portal-arch.img",
              "image_sha256": "abc123",
              "image_signature_url": "https://example.com/portal-arch.img.minisig",
              "kernel_url": "https://example.com/kernel",
              "kernel_sha256": "def456",
              "initrd_url": "https://example.com/initrd",
              "initrd_sha256": "ghi789"
            }
          ]
        }
        """
        let data = Data(json.utf8)
        let manifest = try JSONDecoder().decode(ImageManifest.self, from: data)

        #expect(manifest.schemaVersion == 2)
        #expect(manifest.images.count == 1)
        #expect(manifest.images[0].name == "arch-spin")
        #expect(manifest.images[0].imageSHA256 == "abc123")
    }

    @Test func findsEntryByName() throws {
        let entry = ImageManifestEntry(
            name: "arch-spin", version: "1", arch: "aarch64", minAppVersion: "0.1.0",
            imageURL: URL(string: "https://example.com/img")!, imageSHA256: "a",
            imageSignatureURL: URL(string: "https://example.com/img.minisig")!,
            kernelURL: URL(string: "https://example.com/kernel")!, kernelSHA256: "b",
            initrdURL: URL(string: "https://example.com/initrd")!, initrdSHA256: "c"
        )
        let manifest = ImageManifest(schemaVersion: 2, images: [entry])

        #expect(manifest.entry(named: "arch-spin") == entry)
        #expect(manifest.entry(named: "nope") == nil)
    }
}
