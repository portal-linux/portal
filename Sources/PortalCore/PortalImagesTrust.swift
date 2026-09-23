import Foundation

public enum PortalImagesTrust {
    // the public half of the minisign keypair portal-images CI signs curated
    // disk images with. safe to embed - only the private half (held only in
    // portal-images' GitHub secrets) can produce a signature this verifies.
    public static let publicKey = "RWTTtPXhXGPXG++RWPcDUjSwKiDl0w1FEp/iDIFPG1ww+jcSEPthfKRO"

    // points at the working branch until the portal-images PR merges to
    // develop - update this once that lands, so curated installs read the
    // reviewed default branch instead of an in-progress feature branch.
    public static let manifestURL = URL(
        string: "https://raw.githubusercontent.com/portal-linux/portal-images/chore/scaffold-portal-images/manifest.json"
    )!
}
