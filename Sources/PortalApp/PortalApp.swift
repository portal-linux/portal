import PortalCore
import SwiftUI

@main
struct PortalApp: App {
    var body: some Scene {
        WindowGroup {
            VMWindowView(vmName: LaunchArguments.vmName(from: CommandLine.arguments))
        }
    }
}
