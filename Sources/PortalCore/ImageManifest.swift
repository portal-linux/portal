import Foundation

public struct ImageManifestEntry: Codable, Equatable {
    public let name: String
    public let version: String
    public let arch: String
    public let minAppVersion: String
    public let imageURL: URL
    public let imageSHA256: String
    public let imageSignatureURL: URL
    public let kernelURL: URL
    public let kernelSHA256: String
    public let initrdURL: URL
    public let initrdSHA256: String

    enum CodingKeys: String, CodingKey {
        case name, version, arch
        case minAppVersion = "min_app_version"
        case imageURL = "image_url"
        case imageSHA256 = "image_sha256"
        case imageSignatureURL = "image_signature_url"
        case kernelURL = "kernel_url"
        case kernelSHA256 = "kernel_sha256"
        case initrdURL = "initrd_url"
        case initrdSHA256 = "initrd_sha256"
    }

    public init(
        name: String, version: String, arch: String, minAppVersion: String,
        imageURL: URL, imageSHA256: String, imageSignatureURL: URL,
        kernelURL: URL, kernelSHA256: String, initrdURL: URL, initrdSHA256: String
    ) {
        self.name = name
        self.version = version
        self.arch = arch
        self.minAppVersion = minAppVersion
        self.imageURL = imageURL
        self.imageSHA256 = imageSHA256
        self.imageSignatureURL = imageSignatureURL
        self.kernelURL = kernelURL
        self.kernelSHA256 = kernelSHA256
        self.initrdURL = initrdURL
        self.initrdSHA256 = initrdSHA256
    }
}

public struct ImageManifest: Codable, Equatable {
    public let schemaVersion: Int
    public let images: [ImageManifestEntry]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case images
    }

    public init(schemaVersion: Int, images: [ImageManifestEntry]) {
        self.schemaVersion = schemaVersion
        self.images = images
    }

    public func entry(named name: String) -> ImageManifestEntry? {
        images.first { $0.name == name }
    }
}
