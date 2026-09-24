public enum LaunchArguments {
    public static func vmName(from arguments: [String], default defaultName: String = "arch") -> String {
        arguments.count > 1 ? arguments[1] : defaultName
    }
}
