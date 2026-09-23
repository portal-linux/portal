import Foundation
import Testing
@testable import PortalCore

struct ImageVerifierTests {
    @Test func matchingSHA256Succeeds() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try "hello portal".write(to: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let realHash = try ImageVerifier.sha256Hex(of: tmp)
        #expect(try ImageVerifier.verifySHA256(fileURL: tmp, expectedHex: realHash))
    }

    @Test func mismatchedSHA256Fails() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try "hello portal".write(to: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmp) }

        #expect(try ImageVerifier.verifySHA256(fileURL: tmp, expectedHex: "0000000000000000000000000000000000000000000000000000000000000000") == false)
    }

    @Test func validMinisignSignatureSucceeds() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let keyPath = dir.appendingPathComponent("test.key")
        let pubPath = dir.appendingPathComponent("test.pub")
        let filePath = dir.appendingPathComponent("payload.bin")
        try "payload contents".write(to: filePath, atomically: true, encoding: .utf8)

        try runMinisign(["-G", "-p", pubPath.path, "-s", keyPath.path, "-W"])
        try runMinisign(["-S", "-s", keyPath.path, "-m", filePath.path])

        let publicKey = try String(contentsOf: pubPath, encoding: .utf8)
            .split(separator: "\n").last.map(String.init) ?? ""
        let sigURL = URL(fileURLWithPath: filePath.path + ".minisig")

        #expect(try ImageVerifier.verifyMinisignSignature(
            fileURL: filePath, signatureFileURL: sigURL, publicKey: publicKey
        ))
    }

    @Test func tamperedFileFailsMinisignVerification() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let keyPath = dir.appendingPathComponent("test.key")
        let pubPath = dir.appendingPathComponent("test.pub")
        let filePath = dir.appendingPathComponent("payload.bin")
        try "payload contents".write(to: filePath, atomically: true, encoding: .utf8)

        try runMinisign(["-G", "-p", pubPath.path, "-s", keyPath.path, "-W"])
        try runMinisign(["-S", "-s", keyPath.path, "-m", filePath.path])

        try "tampered contents".write(to: filePath, atomically: true, encoding: .utf8)

        let publicKey = try String(contentsOf: pubPath, encoding: .utf8)
            .split(separator: "\n").last.map(String.init) ?? ""
        let sigURL = URL(fileURLWithPath: filePath.path + ".minisig")

        #expect(try ImageVerifier.verifyMinisignSignature(
            fileURL: filePath, signatureFileURL: sigURL, publicKey: publicKey
        ) == false)
    }
}

private func runMinisign(_ arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/minisign")
    process.arguments = arguments
    process.standardInput = FileHandle.nullDevice
    try process.run()
    process.waitUntilExit()
}
