import SwiftUI
import AppKit
import Virtualization
import PortalCore
import Foundation

struct VMWindowView: View {
    let vmName: String
    @State private var virtualMachine: VZVirtualMachine?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let virtualMachine {
                VMHostView(virtualMachine: virtualMachine)
                    .frame(minWidth: 1280, minHeight: 800)
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

            let bootstrapper = VMBootstrapper(configuration: vmConfig)
            let vzConfig = try bootstrapper.makeVirtualMachineConfiguration(boot: boot, enableGraphics: true)
            try vzConfig.validate()

            let vm = VZVirtualMachine(configuration: vzConfig)
            virtualMachine = vm
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

struct VMHostView: NSViewRepresentable {
    let virtualMachine: VZVirtualMachine

    func makeNSView(context: Context) -> VZVirtualMachineView {
        let view = VZVirtualMachineView()
        view.virtualMachine = virtualMachine
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            view.window?.makeKeyAndOrderFront(nil)
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: VZVirtualMachineView, context: Context) {
        nsView.virtualMachine = virtualMachine
    }
}
