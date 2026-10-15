import AppKit
import ApplicationServices
import FlowCore

/// Paste-with-restore insertion, Wispr's way: put the text on the
/// clipboard, press Cmd+V in the target app, then put the user's previous
/// clipboard back about half a second later (unless they copied something
/// new in between).
@MainActor
public enum Inserter {
    public enum Result { case inserted, copiedOnly }

    public static func insert(_ text: String, rich: NSAttributedString? = nil,
                              into app: NSRunningApplication?, method: InsertionMethod) -> Result {
        guard AXIsProcessTrusted() else {
            VoiceEngine.copyToClipboard(text)
            return .copiedOnly
        }
        guard method == .paste else {
            pasteText(text, into: app)
            return .inserted
        }
        guard activate(app) else {
            VoiceEngine.copyToClipboard(text)
            return .copiedOnly
        }
        let pb = NSPasteboard.general
        let saved = snapshot(pb)
        pb.clearContents()
        if let rich, let rtf = try? rich.data(from: NSRange(location: 0, length: rich.length),
                                              documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
            pb.setData(rtf, forType: .rtf)
        }
        pb.setString(text, forType: .string)
        let ours = pb.changeCount
        pressCommandV()
        // Slow apps (Electron, remote desktops) read the clipboard late.
        let delay: Double = slowApps.contains(where: { app?.bundleIdentifier?.lowercased().contains($0) == true }) ? 3 : 0.6
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard pb.changeCount == ours else { return } // user copied something new
            restore(saved, to: pb)
        }
        return .inserted
    }

    static let slowApps = ["outlook", "microsoft.word", "whatsapp", "remote", "citrix", "parallels"]

    private static func activate(_ app: NSRunningApplication?) -> Bool {
        let me = Bundle.main.bundleIdentifier
        guard let target = app ?? NSWorkspace.shared.frontmostApplication,
              !target.isTerminated, target.bundleIdentifier != me else { return false }
        if NSWorkspace.shared.frontmostApplication?.processIdentifier != target.processIdentifier {
            target.activate()
            let deadline = Date().addingTimeInterval(0.8)
            while Date() < deadline,
                  NSWorkspace.shared.frontmostApplication?.processIdentifier != target.processIdentifier {
                RunLoop.current.run(until: Date().addingTimeInterval(0.03))
            }
        }
        return NSWorkspace.shared.frontmostApplication?.processIdentifier == target.processIdentifier
    }

    private static func pressCommandV() {
        let source = CGEventSource(stateID: .privateState)
        let down = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cgSessionEventTap)
        up?.post(tap: .cgSessionEventTap)
    }

    private static func snapshot(_ pb: NSPasteboard) -> [[NSPasteboard.PasteboardType: Data]] {
        (pb.pasteboardItems ?? []).map { item in
            var d: [NSPasteboard.PasteboardType: Data] = [:]
            for t in item.types { if let data = item.data(forType: t) { d[t] = data } }
            return d
        }
    }

    private static func restore(_ items: [[NSPasteboard.PasteboardType: Data]], to pb: NSPasteboard) {
        pb.clearContents()
        guard !items.isEmpty else { return }
        let restored: [NSPasteboardItem] = items.map { dict in
            let item = NSPasteboardItem()
            for (t, data) in dict { item.setData(data, forType: t) }
            return item
        }
        pb.writeObjects(restored)
    }

    /// Text around the cursor and the window title, for context awareness.
    public static func contextTexts(of app: NSRunningApplication?) -> [String] {
        var out: [String] = []
        let field = VoiceEngine.focusedText()
        if let v = field.value { out.append(String(v.suffix(4000))) }
        if let pid = app?.processIdentifier {
            let axApp = AXUIElementCreateApplication(pid)
            var window: CFTypeRef?
            if AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &window) == .success,
               let w = window {
                var title: CFTypeRef?
                AXUIElementCopyAttributeValue(w as! AXUIElement, kAXTitleAttribute as CFString, &title)
                if let t = title as? String { out.append(t) }
            }
        }
        return out
    }
}
