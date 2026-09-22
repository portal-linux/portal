import Foundation
import Virtualization

public struct VMBootstrapper {
    public let configuration: VMConfiguration

    public init(configuration: VMConfiguration) {
        self.configuration = configuration
    }

    // building a live VZVirtualMachine needs the com.apple.security.virtualization
    // entitlement and a signed app bundle, so this is exercised only on device, not in tests.
    @available(macOS 14.0, *)
    public func makeVirtualMachineConfiguration() throws -> VZVirtualMachineConfiguration {
        let vzConfig = VZVirtualMachineConfiguration()
        vzConfig.cpuCount = configuration.cpuCount
        vzConfig.memorySize = configuration.memoryBytes

        let diskURL = URL(fileURLWithPath: configuration.diskImagePath)
        let attachment = try VZDiskImageStorageDeviceAttachment(url: diskURL, readOnly: false)
        vzConfig.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: attachment)]

        return vzConfig
    }
}
