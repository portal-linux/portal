import Foundation

public enum PortalImagesTrust {
    // the public half of the minisign keypair portal-images CI signs curated
    // disk images with. safe to embed - only the private half (held only in
    // portal-images' GitHub secrets) can produce a signature this verifies.
    public static let publicKey = "RWTTtPXhXGPXG++RWPcDUjSwKiDl0w1FEp/iDIFPG1ww+jcSEPthfKRO"

    public static let manifestURL = URL(
        string: "https://raw.githubusercontent.com/portal-linux/portal-images/develop/manifest.json"
    )!
}
