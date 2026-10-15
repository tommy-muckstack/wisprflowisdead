import AppKit
import FlowCore
import SwiftUI

/// The floating pill. A non-activating panel so clicks never steal focus
/// from the field you are dictating into.
@MainActor
final class FlowBarPanel: NSPanel {
    private let controller: DictationController
    static let size = NSSize(width: 360, height: 150)

    init(controller: DictationController) {
        self.controller = controller
        super.init(contentRect: NSRect(origin: .zero, size: Self.size),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        let host = NSHostingView(rootView: FlowBarRoot(controller: controller, dock: { [weak self] point in
            self?.dock(nearest: point)
        }))
        host.frame = NSRect(origin: .zero, size: Self.size)
        contentView = host
        place()
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Bottom-center above the Dock, or vertically centered on a side edge.
    func place() {
        guard let screen = NSScreen.main else { return }
        let f = screen.visibleFrame
        let origin: NSPoint
        switch controller.settings.flowBarDock {
        case .bottom: origin = NSPoint(x: f.midX - Self.size.width / 2, y: f.minY + 4)
        case .left: origin = NSPoint(x: f.minX - Self.size.width / 2 + 40, y: f.midY - Self.size.height / 2)
        case .right: origin = NSPoint(x: f.maxX - Self.size.width / 2 - 40, y: f.midY - Self.size.height / 2)
        }
        setFrameOrigin(origin)
    }

    /// Called at the end of a drag with the pointer location in screen space.
    func dock(nearest point: NSPoint) {
        guard let f = NSScreen.main?.visibleFrame else { return }
        let distances: [(FlowBarDock, CGFloat)] = [
            (.bottom, point.y - f.minY), (.left, point.x - f.minX), (.right, f.maxX - point.x),
        ]
        let best = distances.min { $0.1 < $1.1 }!.0
        controller.settings.flowBarDock = best
        place()
    }

    func refreshVisibility() {
        let hiddenForHour = controller.hiddenUntil.map { $0 > Date() } ?? false
        let active = controller.phase != .resting || controller.notice != nil
        let visible = controller.settings.onboardingComplete &&
            (active || (controller.settings.showFlowBarAlways && !hiddenForHour))
        if visible { orderFrontRegardless() } else { orderOut(nil) }
    }
}

struct FlowBarRoot: View {
    @ObservedObject var controller: DictationController
    var dock: (NSPoint) -> Void
    @State private var dragging = false

    var body: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)
            if let notice = controller.notice {
                NoticeCard(notice: notice) { controller.perform($0) } dismiss: { controller.notice = nil }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            FlowBarPill(controller: controller)
                .gesture(DragGesture(minimumDistance: 6, coordinateSpace: .global)
                    .onChanged { _ in dragging = true }
                    .onEnded { _ in
                        dragging = false
                        dock(NSEvent.mouseLocation)
                    })
        }
        .padding(.bottom, 6)
        .frame(width: FlowBarPanel.size.width, height: FlowBarPanel.size.height, alignment: .bottom)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: controller.notice)
    }
}

struct FlowBarPill: View {
    @ObservedObject var controller: DictationController

    private var size: CGSize {
        switch controller.phase {
        case .resting: return controller.hovering ? CGSize(width: controller.settings.showScratchpadButton ? 290 : 268, height: 30) : CGSize(width: 40, height: 9)
        case .recording(let handsFree, _): return CGSize(width: handsFree ? 150 : 112, height: 34)
        case .processing: return CGSize(width: 80, height: 34)
        }
    }

    private var isCommand: Bool {
        switch controller.phase {
        case .recording(_, let c), .processing(let c): return c
        case .resting: return false
        }
    }

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Theme.ink.opacity(controller.phase == .resting && !controller.hovering ? 0.55 : 1))
                .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 1))
                .shadow(color: isCommand ? Theme.lavender.opacity(0.9) : .black.opacity(0.25),
                        radius: isCommand ? 10 : 8, y: 3)
            content
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Capsule())
        .onHover { inside in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { controller.hovering = inside }
        }
        .onTapGesture { controller.barClicked() }
        .contextMenu {
            if controller.phase == .resting {
                Button("Hide for 1 hour") { controller.hiddenUntil = Date().addingTimeInterval(3600) }
                Menu("Dock") {
                    ForEach(FlowBarDock.allCases, id: \.self) { d in
                        Button(d.rawValue.capitalized) { controller.settings.flowBarDock = d }
                    }
                }
                Button("Open WisprFlowIsDead") { (NSApp.delegate as? AppDelegate)?.showHub(page: .home) }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: controller.phase)
    }

    @ViewBuilder private var content: some View {
        switch controller.phase {
        case .resting:
            if controller.hovering {
                let key = controller.settings.shortcuts.shortcuts(for: .pushToTalk).first?.display ?? "fn"
                HStack(spacing: 8) {
                    Text("Click or hold \(key) to start dictating")
                        .font(Theme.font(12, .medium))
                        .foregroundStyle(Theme.cream)
                        .lineLimit(1)
                    Menu {
                        ForEach(controller.settings.transforms) { t in
                            Button(t.name) { controller.runTransform(t) }
                        }
                    } label: {
                        Image(systemName: "wand.and.stars").font(.system(size: 11)).foregroundStyle(Theme.cream)
                    }
                    .menuStyle(.borderlessButton).menuIndicator(.hidden).frame(width: 16)
                    .help("Transform selected text")
                    if controller.settings.showScratchpadButton {
                        Button { controller.toggleScratchpad?() } label: {
                            Image(systemName: "note.text").font(.system(size: 11)).foregroundStyle(Theme.cream)
                        }.buttonStyle(.plain).help("Scratchpad")
                    }
                }
                .transition(.opacity)
            }
        case .recording(let handsFree, _):
            HStack(spacing: 8) {
                if handsFree {
                    CircleIcon(system: "xmark", tint: .white.opacity(0.85)) { controller.cancelPressed() }
                }
                Waveform(levels: controller.levels)
                if handsFree {
                    CircleIcon(system: "stop.fill", tint: Theme.orange) { controller.handsFreePressed() }
                }
            }
            .padding(.horizontal, 8)
        case .processing:
            ProcessingDots()
        }
    }
}

struct CircleIcon: View {
    var system: String
    var tint: Color
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.white.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }
}

/// Bars follow the last ~11 level samples, newest on the right.
struct Waveform: View {
    var levels: [CGFloat]
    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(Color.white)
                    .frame(width: 3, height: max(3, 4 + level * 18))
            }
        }
        .frame(height: 22)
    }
}

struct ProcessingDots: View {
    @State private var phase = 0.0
    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    let wave = (sin((t * 2 * .pi / 0.9) - Double(i) * 0.8) + 1) / 2
                    Circle()
                        .fill(Color.white.opacity(0.35 + 0.65 * wave))
                        .frame(width: 5, height: 5)
                        .offset(y: -2 * wave)
                }
            }
        }
    }
}

struct NoticeCard: View {
    var notice: Notice
    var perform: (Notice.Action) -> Void
    var dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(notice.kind == .error ? Theme.orange : notice.kind == .warning ? Theme.amber : Theme.lavender)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text(notice.title).font(Theme.font(13, .semibold)).foregroundStyle(Theme.cream)
                if let body = notice.body {
                    Text(body).font(Theme.font(12)).foregroundStyle(Theme.cream.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !notice.actions.isEmpty {
                    HStack {
                        ForEach(notice.actions, id: \.id) { a in
                            Button(a.title) { perform(a) }
                                .buttonStyle(.plain)
                                .font(Theme.font(12, .semibold))
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Capsule().fill(Theme.cream))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            Spacer(minLength: 0)
            Button(action: dismiss) {
                Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.cream.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 320)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.ink))
        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
    }
}
