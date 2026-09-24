import Testing
@testable import PortalCore

struct LaunchArgumentsTests {
    @Test func usesFirstArgumentAsVMName() {
        #expect(LaunchArguments.vmName(from: ["PortalApp", "mytest"]) == "mytest")
    }

    @Test func fallsBackToDefaultWhenNoArgumentGiven() {
        #expect(LaunchArguments.vmName(from: ["PortalApp"]) == "arch")
    }

    @Test func fallsBackToDefaultWhenArgumentsEmpty() {
        #expect(LaunchArguments.vmName(from: []) == "arch")
    }
}
