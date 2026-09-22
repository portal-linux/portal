import Foundation
import Testing
@testable import PortalCore

struct SharedFolderTests {
    @Test func validFolderSucceeds() throws {
        let folder = try SharedFolder(tag: "mac", hostPath: "/tmp")
        #expect(folder.tag == "mac")
        #expect(folder.hostPath == "/tmp")
    }

    @Test func emptyTagIsRejected() {
        #expect(throws: SharedFolderError.emptyTag) {
            try SharedFolder(tag: "", hostPath: "/tmp")
        }
    }

    @Test func missingHostPathIsRejected() {
        #expect(throws: SharedFolderError.hostPathNotFound) {
            try SharedFolder(tag: "mac", hostPath: "/does/not/exist/portal-test")
        }
    }
}
