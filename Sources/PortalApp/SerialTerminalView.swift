import AppKit
import Foundation
import SwiftTerm
import SwiftUI
import Virtualization

// bridges a vm's serial port (attached via a pipe pair, not host stdio) to a
// SwiftTerm TerminalView: bytes the guest writes get fed to the view for
// display, and keystrokes the view captures get written back to the guest.
//
// @unchecked Sendable: guestOutput/guestInput are set once at init and never
// mutated; terminalView is set once right after the view is created, before
// any bytes flow. the readabilityHandler below only reads it.
final class SerialConsoleController: NSObject, TerminalViewDelegate, @unchecked Sendable {
    private let guestOutput: Pipe
    private let guestInput: Pipe
    weak var terminalView: TerminalView?

    init(guestOutput: Pipe, guestInput: Pipe) {
        self.guestOutput = guestOutput
        self.guestInput = guestInput
        super.init()
        guestOutput.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self else { return }
            Task { @MainActor in
                self.terminalView?.feed(byteArray: ArraySlice(data))
            }
        }
    }

    var serialPortAttachment: VZFileHandleSerialPortAttachment {
        VZFileHandleSerialPortAttachment(
            fileHandleForReading: guestInput.fileHandleForReading,
            fileHandleForWriting: guestOutput.fileHandleForWriting
        )
    }

    func stop() {
        guestOutput.fileHandleForReading.readabilityHandler = nil
    }

    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        guestInput.fileHandleForWriting.write(Data(data))
    }

    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {}
    func setTerminalTitle(source: TerminalView, title: String) {}
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
    func scrolled(source: TerminalView, position: Double) {}
    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}
}

struct SerialTerminalView: NSViewRepresentable {
    let controller: SerialConsoleController

    func makeNSView(context: Context) -> TerminalView {
        let view = TerminalView(frame: .zero)
        view.terminalDelegate = controller
        controller.terminalView = view
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            view.window?.makeKeyAndOrderFront(nil)
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: TerminalView, context: Context) {}
}
