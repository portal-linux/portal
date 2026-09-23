import Foundation
import Virtualization

// VZVirtualMachine dispatches its callbacks onto the run loop it was created on
// (the main thread here), so this blocks by spinning that run loop rather than
// with a semaphore, which would starve the callbacks it is waiting for.
@available(macOS 14.0, *)
public final class VMRunner: NSObject, VZVirtualMachineDelegate {
    private var shouldStop = false
    private var startError: Error?
    public private(set) var stopError: Error?

    public override init() {
        super.init()
    }

    public func run(configuration: VZVirtualMachineConfiguration) throws {
        try configuration.validate()

        let vm = VZVirtualMachine(configuration: configuration)
        vm.delegate = self

        vm.start { [weak self] result in
            if case .failure(let error) = result {
                self?.startError = error
                self?.shouldStop = true
            }
        }

        while !shouldStop {
            RunLoop.main.run(mode: .default, before: .distantFuture)
        }

        if let startError {
            throw startError
        }
        if let stopError {
            throw stopError
        }
    }

    public func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        shouldStop = true
    }

    public func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        stopError = error
        shouldStop = true
    }
}
