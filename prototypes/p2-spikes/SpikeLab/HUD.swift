// The HUD on every spike screen (P2 plan §B.1): fps, frame time, whole-app memory footprint, thermal state, battery.
import SwiftUI
import QuartzCore

@MainActor @Observable
final class FrameMeter {
    private(set) var fps: Double = 0
    private(set) var worstFrameMs: Double = 0
    private(set) var footprintMB: Double = 0
    private(set) var thermal: String = ""
    private(set) var battery: Int = -1

    private var link: CADisplayLink?
    private var last: CFTimeInterval = 0
    private var frames = 0
    private var windowStart: CFTimeInterval = 0
    private var worst: CFTimeInterval = 0

    func start() {
        guard link == nil else { return }
        UIDevice.current.isBatteryMonitoringEnabled = true
        let l = CADisplayLink(target: self, selector: #selector(tick(_:)))
        l.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        l.add(to: .main, forMode: .common)
        link = l
    }

    func stop() { link?.invalidate(); link = nil }

    @objc private func tick(_ l: CADisplayLink) {
        let now = l.timestamp
        if last > 0 { worst = max(worst, now - last) }
        last = now
        frames += 1
        if windowStart == 0 { windowStart = now }
        if now - windowStart >= 1 {
            fps = Double(frames) / (now - windowStart)
            worstFrameMs = worst * 1000
            footprintMB = Self.footprint()
            thermal = Self.thermalName(ProcessInfo.processInfo.thermalState)
            battery = Int(UIDevice.current.batteryLevel * 100)
            frames = 0; worst = 0; windowStart = now
        }
    }

    /// Whole-process physical footprint (what the system counts against the app), in MB.
    static func footprint() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return kr == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : -1
    }

    static func thermalName(_ s: ProcessInfo.ThermalState) -> String {
        switch s {
        case .nominal: "nominal"
        case .fair: "fair"
        case .serious: "SERIOUS"
        case .critical: "CRITICAL"
        @unknown default: "?"
        }
    }
}

struct HUDView: View {
    let meter: FrameMeter
    var body: some View {
        HStack(spacing: 10) {
            Text(String(format: "%.0f fps", meter.fps))
            Text(String(format: "worst %.1f ms", meter.worstFrameMs))
            Text(String(format: "%.0f MB", meter.footprintMB))
            Text(meter.thermal)
            Text(meter.battery >= 0 ? "\(meter.battery)%" : "–")
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.black.opacity(0.6), in: Capsule())
        .foregroundStyle(.white)
    }
}
