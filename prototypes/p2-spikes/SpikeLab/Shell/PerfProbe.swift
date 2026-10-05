// Performance probe (-perf): times every frame the main thread delivers (what you actually see and touch), logs the
// frame rate and every hitch with what was on screen, and times suspicious work (image decoding, tinting, building).
// Used with -uitest, a scripted tour on the real phone: sheets, scrolling, looking around, the map, a realm.
import SwiftUI
import QuartzCore

@MainActor
final class PerfProbe: NSObject {
    static let shared = PerfProbe()
    static let on = CommandLine.arguments.contains("-perf")
    var phase = "start"
    private var link: CADisplayLink?
    private var last: CFTimeInterval = 0, windowStart: CFTimeInterval = 0
    private var frames = 0, hitches = 0, worst: Double = 0, dropped = 0

    func start() {
        guard Self.on, link == nil else { return }
        let l = CADisplayLink(target: self, selector: #selector(tick(_:)))
        l.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        l.add(to: .main, forMode: .common)
        link = l
    }

    @objc private func tick(_ l: CADisplayLink) {
        let now = l.timestamp
        if last > 0 {
            let dt = now - last
            let expected = l.targetTimestamp - l.timestamp
            worst = max(worst, dt)
            if dt > max(0.024, expected * 1.6) {
                hitches += 1; dropped += Int((dt / max(expected, 0.008)).rounded()) - 1
                if dt > 0.05 { print(String(format: "HITCH %.0f ms during [%@]", dt * 1000, phase)) }
            }
        }
        last = now; frames += 1
        if windowStart == 0 { windowStart = now }
        if now - windowStart >= 1 {
            let b = bodies.sorted { $0.value > $1.value }.prefix(5).map { "\($0.key)×\($0.value)" }.joined(separator: " ")
            print(String(format: "UI fps %.0f  hitches %d  dropped %d  worst %.0f ms  [%@]  redraws: %@", Double(frames) / (now - windowStart), hitches, dropped, worst * 1000, phase, b))
            bodies.removeAll()
            frames = 0; hitches = 0; dropped = 0; worst = 0; windowStart = now
        }
    }

    /// Counts how often a view's body is re-evaluated (logged with the frame rate each second).
    private var bodies: [String: Int] = [:]
    static func body(_ name: String) { guard on else { return }; shared.bodies[name, default: 0] += 1 }

    /// Times a piece of work on the main thread; logs it when it costs more than a few milliseconds.
    @discardableResult
    static func measure<T>(_ label: String, _ work: () -> T) -> T {
        guard on else { return work() }
        let t0 = CACurrentMediaTime()
        let r = work()
        let ms = (CACurrentMediaTime() - t0) * 1000
        if ms > 3 { print(String(format: "SLOW %@ %.1f ms", label, ms)) }
        return r
    }
}

extension Notification.Name {
    static let perfScroll = Notification.Name("perfScroll")
    static let perfCommand = Notification.Name("perfCommand")
}

/// (-uitest -perf) The scripted tour, run from the shell so it carries on across screens.
@MainActor
func runUITest(_ model: ShellModel) async {
    let p = PerfProbe.shared
    func phase(_ name: String, _ s: Double) async { p.phase = name; try? await Task.sleep(for: .seconds(s)) }
    func cmd(_ c: String) { NotificationCenter.default.post(name: .perfCommand, object: c) }
    func scroll(_ to: String) { NotificationCenter.default.post(name: .perfScroll, object: to) }
    while !model.coreReady { try? await Task.sleep(for: .milliseconds(200)) }
    await phase("home idle", 4)
    p.phase = "home look around"
    for c in ["panR", "panL", "panR", "pan0"] { cmd(c); try? await Task.sleep(for: .seconds(1.1)) }
    for sheet in ["satchel", "flame", "book"] {
        p.phase = "\(sheet) opening"; cmd(sheet)
        await phase("\(sheet) opening", 1.0)
        p.phase = "\(sheet) scrolling"
        for k in 0..<4 { scroll(k % 2 == 0 ? "bottom" : "top"); try? await Task.sleep(for: .seconds(1.3)) }
        p.phase = "\(sheet) closing"; cmd("close")
        await phase("\(sheet) closing", 1.0)
    }
    p.phase = "to the map"; withAnimation(.screen) { model.go(.map) }
    await phase("map", 3)
    p.phase = "map moving"
    for k in 0..<3 { model.mapScene.panTarget = [0, k % 2 == 0 ? 0.25 : -0.25]; try? await Task.sleep(for: .seconds(1.2)) }
    p.phase = "to the grove"; withAnimation(.screen) { model.go(.realm(.grove)) }
    await phase("grove", 3)
    p.phase = "grove look around"
    for c in ["panR", "panL", "pan0"] { cmd(c); try? await Task.sleep(for: .seconds(1.1)) }
    p.phase = "back home"; withAnimation(.screen) { model.go(.home) }
    await phase("home again", 3)
    print("UITEST DONE")
}
