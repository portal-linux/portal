import Foundation

public enum RosettaAvailability: Equatable {
    case notSupported
    case notInstalled
    case installed
}

public enum RosettaSupport {
    public static func shouldEnable(for availability: RosettaAvailability) -> Bool {
        availability == .installed
    }
}
