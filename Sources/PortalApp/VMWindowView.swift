import SwiftUI
import AppKit
import Virtualization
import PortalCore
import Foundation

struct VMWindowView: View {
    let vmName: String
    @State private var virtualMachine: VZVirtualMachine?
    @State private var consoleController: SerialConsoleController?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if virtualMachine != nil, let consoleController {
                SerialTerminalView(controller: consoleController)
                    .frame(minWidth: 960, minHeight: 600)
                    .onDisappear { consoleController.stop() }
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding()
                    .frame(minWidth: 480, minHeight: 320)
            } else {
                ProgressView("starting \(vmName)...")
                    .padding()
                    .frame(minWidth: 480, minHeight: 320)
                    .onAppear(perform: start)
            }
        }
    }

    private func start() {
        do {
            let base = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Portal/vms", isDirectory: true)
            let store = VMStore(baseDirectory: base)
            let paths = store.paths(for: vmName)

            let data = try Data(contentsOf: paths.manifest)
            let manifest = try JSONDecoder().decode(VMManifest.self, from: data)

            let vmConfig = try VMConfiguration(
                cpuCount: manifest.cpuCount,
                memoryBytes: manifest.memoryBytes,
                diskImagePath: manifest.diskImagePath
            )
            let boot = BootImage(
                kernelURL: URL(fileURLWithPath: manifest.kernelPath),
                initialRamdiskURL: manifest.initialRamdiskPath.map { URL(fileURLWithPath: $0) },
                commandLine: manifest.commandLine
            )

            let controller = SerialConsoleController(guestOutput: Pipe(), guestInput: Pipe())
            let bootstrapper = VMBootstrapper(configuration: vmConfig)
            let vzConfig = try bootstrapper.makeVirtualMachineConfiguration(
                boot: boot,
                serialPortAttachment: controller.serialPortAttachment
            )
            try vzConfig.validate()

            let vm = VZVirtualMachine(configuration: vzConfig)
            virtualMachine = vm
            consoleController = controller
            vm.start { result in
                if case .failure(let error) = result {
                    DispatchQueue.main.async {
                        errorMessage = "failed to start: \(error.localizedDescription)"
                    }
                }
            }
        } catch {
            errorMessage = "\(error)"
        }
    }
}
