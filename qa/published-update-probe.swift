import Foundation
import AppKit
import Sparkle

@MainActor final class Probe: NSObject, SPUUpdaterDelegate {
    func feedURLString(for updater: SPUUpdater) -> String? { CommandLine.arguments[1] }
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        print("SPARKLE_VERIFIED_UPDATE version=\(item.versionString)")
        exit(0)
    }
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        print("SPARKLE_REJECTED \(error)")
        exit(2)
    }
    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        print("SPARKLE_NO_UPDATE \(error)")
        exit(3)
    }
}
MainActor.assumeIsolated {
    let bundle = Bundle.main
    let delegate = Probe()
    let driver = SPUStandardUserDriver(hostBundle: bundle, delegate: nil)
    let updater = SPUUpdater(hostBundle: bundle, applicationBundle: bundle, userDriver: driver, delegate: delegate)
    do { try updater.start() } catch { print("START_FAILED \(error)"); exit(4) }
    DispatchQueue.main.async { updater.checkForUpdateInformation() }
    DispatchQueue.main.asyncAfter(deadline: .now() + 25) { print("TIMEOUT"); exit(5) }
    withExtendedLifetime((delegate, driver, updater)) { RunLoop.main.run() }
}
