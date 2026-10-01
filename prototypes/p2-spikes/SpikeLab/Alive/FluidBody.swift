// Fluid, physics-based motion for a character (Mathis: "its movement should be more fluid"). Updated every frame:
// springs with a little overshoot instead of fixed tweens, a continuous organic drift, real hops with gravity,
// automatic squash and stretch from speed, leaning into motion, and follow-through values for the flame hair.
import Foundation

/// Smooth 1D value noise (a few octaves), seeded: organic wandering that never repeats.
struct SmoothNoise {
    private var table: [Float]
    init(seed: UInt64) {
        var rng = SeededRandom(seed: seed)
        table = (0..<256).map { _ in Float.random(in: -1...1, using: &rng) }
    }
    private func value(_ x: Float) -> Float {
        let i = Int(floor(x)), f = x - floor(x)
        let a = table[((i % 256) + 256) % 256], b = table[(((i + 1) % 256) + 256) % 256]
        let t = f * f * (3 - 2 * f)
        return a + (b - a) * t
    }
    func sample(_ x: Float) -> Float {
        value(x) * 0.6 + value(x * 2.1 + 17.3) * 0.28 + value(x * 4.3 + 41.7) * 0.12
    }
}

/// A damped spring toward a target: slightly underdamped, so motions overshoot a touch and settle, like weight.
struct Spring {
    var value: Float, velocity: Float = 0
    var stiffness: Float, damping: Float
    init(_ v: Float, stiffness: Float = 60, damping: Float = 9) { value = v; self.stiffness = stiffness; self.damping = damping }
    mutating func step(toward target: Float, dt: Float) {
        let a = stiffness * (target - value) - damping * velocity
        velocity += a * dt
        value += velocity * dt
    }
}

struct FluidBody {
    // Outputs, read every frame by the rig.
    private(set) var x: Float = 0, y: Float = 0
    private(set) var roll: Float = 0
    private(set) var scaleX: Float = 1, scaleY: Float = 1
    private(set) var hairDrag = SIMD2<Float>(0, 0)          // follow-through for the hair shader (meters)

    // Behavior inputs (set by the rig's idles and reactions).
    var wanderRange: Float = 0.06
    var energy: Float = 0.8                                 // mood: drift speed and amplitude
    var extraRoll: Float = 0                                // a held tilt (glance, rock)
    var stretchTarget: Float = 1                            // >1 stretch, <1 squash (yawn, doze, stretch)
    var bias: Float = 0                                     // lean toward the finger, or a wander destination
    var resting = false                                     // doze: almost still

    private var time: Float = 0
    private let noise: SmoothNoise
    private var xs = Spring(0, stiffness: 14, damping: 5.5)  // travel: soft and floaty
    private var rolls = Spring(0, stiffness: 40, damping: 6)
    private var squash = Spring(1, stiffness: 140, damping: 7) // jiggly
    private var hairX = Spring(0, stiffness: 30, damping: 4)
    private var hairY = Spring(0, stiffness: 30, damping: 4)
    private var vy: Float = 0
    private let gravity: Float = 2.2                         // cartoony: slow, readable hops

    init(seed: UInt64) { noise = SmoothNoise(seed: seed) }

    /// A real hop: an upward kick; gravity brings it back, and landing squashes it according to impact speed.
    mutating func hop(height: Float) {
        guard y < 0.002 else { vy += sqrt(2 * gravity * height) * 0.5; return }
        squash.velocity -= 2.5                               // crouch before the jump
        vy = sqrt(2 * gravity * height)
    }

    mutating func step(dt rawDt: Float) {
        let dt = min(rawDt, 1.0 / 30)                         // stay stable through a dropped frame
        time += dt
        let e = resting ? 0.15 : (0.45 + energy * 0.75)

        // Travel: an endless smooth path across the ground, plus wherever a behavior wants to go.
        let drift = noise.sample(time * 0.11 * e) * wanderRange
        let target = max(-wanderRange * 1.3, min(wanderRange * 1.3, drift + bias))
        let oldX = xs.value
        xs.step(toward: target, dt: dt)
        x = xs.value
        let vx = (x - oldX) / max(dt, 0.0001)

        // Hops with gravity.
        vy -= gravity * dt
        y += vy * dt
        if y <= 0 {
            if vy < -0.15 { squash.velocity -= min(6, -vy * 9) }   // landing impact → squash, then jiggle back
            y = 0; vy = 0
        }

        // Squash and stretch from vertical speed, on top of a held stretch (yawn, doze), plus a breath.
        let breath = sin(time * 1.7) * 0.012 * (resting ? 0.6 : 1)
        let speedStretch = max(-0.08, min(0.1, vy * 0.35))
        squash.step(toward: stretchTarget + speedStretch + breath, dt: dt)
        scaleY = squash.value
        scaleX = 1 / sqrt(max(0.6, scaleY))                  // keep the volume: taller means thinner

        // Lean into motion, sway gently, and hold any behavior tilt.
        let sway = noise.sample(time * 0.37 * e + 50) * 0.05 * e
        rolls.step(toward: -vx * 0.9 + sway + extraRoll, dt: dt)
        roll = rolls.value

        // Follow-through: the hair trails behind horizontal motion and lags vertical motion, then catches up.
        hairX.step(toward: -vx * 0.05, dt: dt)
        hairY.step(toward: -vy * 0.012, dt: dt)
        hairDrag = SIMD2(hairX.value, hairY.value)
    }
}
