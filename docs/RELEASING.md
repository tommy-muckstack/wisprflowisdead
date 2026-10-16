# Mac installer and automatic updates

Sparkle 2.10.0 is pinned by its official binary checksum. The app retains one `SPUStandardUpdaterController`, starts it after launch, and exposes Check for Updates in the menu bar. Automatic checking/downloading is enabled; profile reporting is disabled. Both the feed and archive require Ed25519 signatures.

`release/config.json` contains the public key, version, monotonically increasing build number, and stable HTTPS feed URL. Never replace that public key casually: installed copies trust it for future updates. Keep the signing private key backed up securely outside Git. This Mac stores it at `~/Library/Application Support/WisprFlowIsDead/Signing/update-ed25519.key`, with directory mode 700 and file mode 600 because Keychain access was unavailable during setup.

Run `bash scripts/package-release.sh` to create the PKG, update ZIP, signed appcast, and checksums under `.build/releases/<version>/`. `UPDATE_KEY_FILE` can select another protected key file. The default app is ad-hoc signed. Set `SIGNING_IDENTITY` (Developer ID Application), `INSTALLER_IDENTITY` (Developer ID Installer), and `NOTARY_PROFILE` to sign and notarize a public distribution. No certificates or credentials are committed. The PKG installs into `/Applications` and disables bundle relocation.

Verify the extracted PKG with `python3 qa/verify-native-app.py <app-path>` and the feed/archive with `swift scripts/verify-release.swift <release-directory>`. These inspect real bundled helpers, runtime linkage, resources, code signatures and cryptographic signatures. Verify a complete update/relaunch cycle on a logged-in Mac separately.

Normal publication: merge the reviewed source, create a GitHub release targeting that merged commit, and upload the generated PKG, ZIP, appcast and checksums without changing their bytes. After confirming the assets are available, copy the signed appcast unchanged to `updates/appcast.xml` on main. Do not publish a feed pointing to an unavailable archive. Never overwrite an existing version: increment both version and build for a new release.

If local GitHub CLI networking is unavailable, the GitHub connector can stage binary chunks on a separate `release/upload-*` branch. `.release-payload/manifest.json` records the merged source commit and every artifact's SHA-256/ordered chunk paths. The publishing workflow reassembles them, checks public-key signatures and the PKG bundle, requires the source to be an ancestor of main, and creates the GitHub release. Binary staging branches are never merged into main. The private signing key never leaves this Mac.

The initial 0.1.0 installer is Apple silicon only, ad-hoc signed and not notarized. A Developer ID identity was unavailable. The website's 90+ home/pricing parity goal and real microphone/native visual checks remain outstanding.
