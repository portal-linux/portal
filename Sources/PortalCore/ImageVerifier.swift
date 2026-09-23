import CryptoKit
import Foundation

public enum ImageVerifierError: Error {
    case minisignNotFound
    case fileReadFailed
}

public enum ImageVerifier {
    public static func sha256Hex(of fileURL: URL) throws -> String {
        let data = try Data(contentsOf: fileURL)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public static func verifySHA256(fileURL: URL, expectedHex: String) throws -> Bool {
        try sha256Hex(of: fileURL).lowercased() == expectedHex.lowercased()
    }

    public static func verifyMinisignSignature(
        fileURL: URL,
        signatureFileURL: URL,
        publicKey: String
    ) throws -> Bool {
        let process = Process()
        process.executableURL = try findMinisign()
        process.arguments = [
            "-Vm", fileURL.path,
            "-x", signatureFileURL.path,
            "-P", publicKey,
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        return process.terminationStatus == 0
    }

    private static func findMinisign() throws -> URL {
        let candidates = ["/opt/homebrew/bin/minisign", "/usr/local/bin/minisign", "/usr/bin/minisign"]
        for candidate in candidates where FileManager.default.fileExists(atPath: candidate) {
            return URL(fileURLWithPath: candidate)
        }
        throw ImageVerifierError.minisignNotFound
    }
}
