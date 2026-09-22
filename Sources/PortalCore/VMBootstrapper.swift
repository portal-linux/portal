import Foundation
import Virtualization

public struct BootImage {
    public let kernelURL: URL
    public let initialRamdiskURL: URL?
    public let commandLine: String

    public init(kernelURL: URL, initialRamdiskURL: URL? = nil, commandLine: String) {
        self.kernelURL = kernelURL
        self.initialRamdiskURL = initialRamdiskURL
        self.commandLine = commandLine
    }
}

public struct VMBootstrapper {
    public let configuration: VMConfiguration

    public init(configuration: VMConfiguration) {
        self.configuration = configuration
    }

    // building and starting a live VZVirtualMachine needs the
    // com.apple.security.virtualization entitlement and real hardware, so this is
    // exercised only on device (via `portal start`), not in unit tests.
    @available(macOS 14.0, *)
    public func makeVirtualMachineConfiguration(
        boot: BootImage,
        sharedFolder: SharedFolder? = nil
    ) throws -> VZVirtualMachineConfiguration {
        let vzConfig = VZVirtualMachineConfiguration()
        vzConfig.cpuCount = configuration.cpuCount
        vzConfig.memorySize = configuration.memoryBytes

        let bootLoader = VZLinuxBootLoader(kernelURL: boot.kernelURL)
        bootLoader.commandLine = boot.commandLine
        if let initialRamdiskURL = boot.initialRamdiskURL {
            bootLoader.initialRamdiskURL = initialRamdiskURL
        }
        vzConfig.bootLoader = bootLoader

        let diskURL = URL(fileURLWithPath: configuration.diskImagePath)
        let diskAttachment = try VZDiskImageStorageDeviceAttachment(url: diskURL, readOnly: false)
        vzConfig.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)]

        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        vzConfig.networkDevices = [networkDevice]

        let serialPort = VZVirtioConsoleDeviceSerialPortConfiguration()
        serialPort.attachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: .standardInput,
            fileHandleForWriting: .standardOutput
        )
        vzConfig.serialPorts = [serialPort]

        if let sharedFolder {
            let device = VZVirtioFileSystemDeviceConfiguration(tag: sharedFolder.tag)
            let url = URL(fileURLWithPath: sharedFolder.hostPath, isDirectory: true)
            device.share = VZSingleDirectoryShare(directory: VZSharedDirectory(url: url, readOnly: false))
            vzConfig.directorySharingDevices = [device]
        }

        return vzConfig
    }
}
