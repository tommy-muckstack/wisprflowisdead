import Foundation

// Shims for the two MyMan types the vendored cleanup code references.
// MyMan stores vocabulary in ~/MyManBrain; WisprFlowIsDead keeps its data in
// Application Support. The people registry does not exist here.
enum Brain {
    static var root: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("WisprFlowIsDead", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
}

enum People {
    static func vocabularyTerms() -> [String] { [] }
}
