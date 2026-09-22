import Testing
@testable import PortalCore

struct RosettaSupportTests {
    @Test func installedMeansEnabled() {
        #expect(RosettaSupport.shouldEnable(for: .installed) == true)
    }

    @Test func notInstalledMeansDisabled() {
        #expect(RosettaSupport.shouldEnable(for: .notInstalled) == false)
    }

    @Test func notSupportedMeansDisabled() {
        #expect(RosettaSupport.shouldEnable(for: .notSupported) == false)
    }
}
