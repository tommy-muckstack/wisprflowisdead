import FlowCore
import Foundation

/// Notetaker capture: your mic and (optionally) everything the Mac plays,
/// transcribed in 30-second pieces as two speakers, "You" and "Others".
/// No bot joins the call; nothing leaves the Mac.
@MainActor
public final class MeetingRecorder: ObservableObject {
    @Published public private(set) var isRecording = false
    @Published public private(set) var segments: [Meeting.Segment] = []
    @Published public private(set) var elapsed: Double = 0

    private var micSession: UUID?
    private var tap: SystemAudioTap?
    private var systemBuffer: [Float] = []
    private let systemLock = NSLock()
    private var started = Date()
    private var chunkStart: Double = 0
    private var timer: Timer?
    private var pending = 0

    public init() {}

    /// Starts capture. System audio needs the "System Audio Recording Only"
    /// permission; if that fails we keep going with the mic alone.
    public func start(includeSystemAudio: Bool) async throws {
        guard !isRecording else { return }
        micSession = try await AudioCapture.shared.begin(.raw)
        if includeSystemAudio {
            let t = SystemAudioTap()
            t.onSamples = { [weak self] samples in
                guard let self else { return }
                self.systemLock.lock(); self.systemBuffer.append(contentsOf: samples); self.systemLock.unlock()
            }
            do { try t.start(); tap = t } catch { NSLog("WisprFlowIsDead [Notetaker] system audio unavailable: \(error)") }
        }
        started = Date(); chunkStart = 0; segments = []; isRecording = true
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.flush() }
        }
    }

    /// Stops capture and returns once the last piece is transcribed.
    public func stop() async -> (segments: [Meeting.Segment], duration: Double) {
        guard isRecording else { return (segments, elapsed) }
        timer?.invalidate(); timer = nil
        await flush(final: true)
        isRecording = false
        tap?.stop(); tap = nil
        elapsed = Date().timeIntervalSince(started)
        return (Meeting.merge(segments), elapsed)
    }

    private func flush(final: Bool = false) async {
        guard let id = micSession else { return }
        let mic = final ? AudioCapture.shared.end(id) : AudioCapture.shared.drain(id)
        if final { micSession = nil }
        systemLock.lock(); let system = systemBuffer; systemBuffer = []; systemLock.unlock()
        let at = chunkStart
        chunkStart = Date().timeIntervalSince(started)
        elapsed = chunkStart
        let engine = VoiceEngine.shared
        if mic.count > 8_000, (mic.map(abs).max() ?? 0) > 0.01 {
            let text = await engine.transcribe(mic)
            if !text.isEmpty { segments.append(.init(speaker: "You", start: at, text: text)) }
        }
        if system.count > 8_000, (system.map(abs).max() ?? 0) > 0.01 {
            let text = await engine.transcribe(system)
            if !text.isEmpty { segments.append(.init(speaker: "Others", start: at, text: text)) }
        }
    }
}
