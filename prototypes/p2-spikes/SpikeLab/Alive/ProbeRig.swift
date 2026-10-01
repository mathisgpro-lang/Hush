// Route A placeholder: the alive system driving the Blender probe Flame. Routes B and C get their own FlameRig.
// Three nested entities keep concerns separate: lean (phone tilt) → look (eyes/idle glances) → the model.
import RealityKit
import UIKit

@MainActor
final class ProbeRig: FlameRig {
    let leanPivot = Entity()
    let lookPivot = Entity()
    private let probe: ProbeModel
    private var lookYawPitch = SIMD2<Float>(0, 0)
    private var idleYawPitch = SIMD2<Float>(0, 0)
    private var eyesHeldClosed = false
    private var restY: Float = 0

    init(probe: ProbeModel, model: Entity) {
        self.probe = probe
        leanPivot.addChild(lookPivot)
        lookPivot.addChild(model)
        restY = lookPivot.position.y
    }

    // MARK: Idle

    func perform(_ idle: IdleBehavior) {
        switch idle {
        case .glanceLeft: glance(SIMD2(0.45, 0), hold: 1.4)
        case .glanceRight: glance(SIMD2(-0.45, 0), hold: 1.4)
        case .glanceUp: glance(SIMD2(0, 0.35), hold: 1.2)
        case .lookAtYou: glance(SIMD2(0, -0.05), hold: 1.8)
        case .watchEmber:
            glance(SIMD2(0.2, 0.3), hold: 0.8)
            after(0.9) { self.glance(SIMD2(-0.15, 0.45), hold: 1.0) }
        case .stretch:
            probe.setSpeed(0.6); probe.playCheer()
            after(1.6) { self.probe.setSpeed(1) }
        case .smallHop: probe.playCheer()
        case .yawn: closeEyes(for: 1.2)
        case .doze: closeEyes(for: 3.5)
        case .hum, .sway: rock(times: 2, angle: 0.08)
        }
    }

    // MARK: Reactions

    func react(_ reaction: Reaction) {
        switch reaction {
        case .giggle:
            probe.setFace(1)                      // happy squint shows on the very next frame
            probe.playCheer()
            after(0.45) { self.openEyesIfAwake() }
        case .leanIn:
            move(lookPivot, scale: 1.06, y: restY + 0.01, duration: 0.25)
            after(0.7) { self.move(self.lookPivot, scale: 1, y: self.restY, duration: 0.35) }
        case .cheer: probe.playCheer()
        case .pillar(let p):
            switch p {
            case .body: probe.playCheer()                                   // a determined little hop
            case .mind: glance(SIMD2(0, 0), roll: 0.18, hold: 1.0)          // curious head tilt
            case .heart: closeEyes(for: 0.9); pulse()                       // warm self-hug
            case .spirit: move(lookPivot, scale: 1, y: restY + 0.02, duration: 0.8)
                after(1.6) { self.move(self.lookPivot, scale: 1, y: self.restY, duration: 0.8) }
            case .craft: glance(SIMD2(0, -0.25), hold: 0.3)                 // a quick focused nod
            case .world: rock(times: 1, angle: 0.12)
            }
        }
    }

    func blink() {
        guard !eyesHeldClosed else { return }
        probe.setFace(1)
        after(0.14) { self.openEyesIfAwake() }
    }

    func look(at point: SIMD2<Float>?) {
        lookYawPitch = point.map { SIMD2($0.x * 0.4, $0.y * 0.3) } ?? .zero
        applyOrientation(duration: 0.12)
    }

    func lean(_ tilt: SIMD2<Float>) {
        let roll = max(-0.35, min(0.35, tilt.x * 0.5))
        let pitch = max(-0.2, min(0.2, tilt.y * 0.3))
        leanPivot.orientation = simd_quatf(angle: -roll, axis: [0, 0, 1]) * simd_quatf(angle: pitch, axis: [1, 0, 0])
    }

    func setMood(_ mood: Float, season: AliveInputs.Season, timeOfDay: AliveInputs.TimeOfDay) {
        let tint: UIColor = switch season {
        case .thaw: UIColor(red: 1.0, green: 0.62, blue: 0.35, alpha: 1)
        case .longLight: UIColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 1)
        case .harvest: UIColor(red: 0.95, green: 0.42, blue: 0.12, alpha: 1)
        case .embernight: UIColor(red: 0.9, green: 0.35, blue: 0.2, alpha: 1)
        }
        let night: Float = timeOfDay == .night ? 0.6 : 1
        probe.setBodyGlow(intensity: (0.15 + mood * 0.85) * night, tint: tint)
        probe.setSpeed(0.7 + mood * 0.4)
        if timeOfDay == .night && mood < 0.3 { eyesHeldClosed = true; probe.setFace(1) }
        else if eyesHeldClosed { eyesHeldClosed = false; probe.setFace(0) }
    }

    func mouth(_ open: Float) {}   // the probe has no mouth parts; routes B and C implement it

    // MARK: Helpers

    private func glance(_ yawPitch: SIMD2<Float>, roll: Float = 0, hold: Double) {
        idleYawPitch = yawPitch
        applyOrientation(duration: 0.35, roll: roll)
        after(hold) {
            self.idleYawPitch = .zero
            self.applyOrientation(duration: 0.5)
        }
    }

    private func applyOrientation(duration: Double, roll: Float = 0) {
        let yp = lookYawPitch + idleYawPitch
        var t = lookPivot.transform
        t.rotation = simd_quatf(angle: yp.x, axis: [0, 1, 0]) * simd_quatf(angle: -yp.y, axis: [1, 0, 0])
            * simd_quatf(angle: roll, axis: [0, 0, 1])
        lookPivot.move(to: t, relativeTo: leanPivot, duration: duration, timingFunction: .easeInOut)
    }

    private func move(_ e: Entity, scale: Float, y: Float, duration: Double) {
        var t = e.transform
        t.scale = .init(repeating: scale)
        t.translation.y = y
        e.move(to: t, relativeTo: e.parent, duration: duration, timingFunction: .easeInOut)
    }

    private func rock(times: Int, angle: Float) {
        for i in 0..<(times * 2) {
            after(Double(i) * 0.45) { self.glance(.zero, roll: i.isMultiple(of: 2) ? angle : -angle, hold: 0.4) }
        }
    }

    private func pulse() {
        move(lookPivot, scale: 1.04, y: restY, duration: 0.3)
        after(0.35) { self.move(self.lookPivot, scale: 1, y: self.restY, duration: 0.4) }
    }

    private func closeEyes(for seconds: Double) {
        eyesHeldClosed = true
        probe.setFace(1)
        after(seconds) { self.eyesHeldClosed = false; self.openEyesIfAwake() }
    }

    private func openEyesIfAwake() { if !eyesHeldClosed { probe.setFace(0) } }

    private func after(_ seconds: Double, _ work: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            work()
        }
    }
}
