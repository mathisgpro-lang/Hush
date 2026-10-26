import Foundation
import RealityKit

/// Registration of an outpaint around the original artwork. Original world coordinates never change.
struct WorldSurround: Decodable {
    let scale: [Float]
    let center: [Float]
    let circle: [Float]?

    static func load(_ realm: String) -> Self? {
        guard let url = Bundle.main.url(forResource: "\(realm)-wide-surround", withExtension: "json"),
              let data = try? Data(contentsOf: url), let result = try? JSONDecoder().decode(Self.self, from: data),
              result.scale.count == 2, result.center.count == 2,
              result.scale.allSatisfy({ $0 > 0 && $0 < 1 }),
              result.center.allSatisfy({ $0 > 0 && $0 < 1 }) else { return nil }
        return result
    }

    var coverage: SIMD2<Float> {
        SIMD2(min(2.8, 2 * min(center[0], 1 - center[0]) / scale[0] - 0.04),
              min(1.8, 2 * min(center[1], 1 - center[1]) / scale[1] - 0.04))
    }

    var circleUV: SIMD2<Float>? {
        guard let circle, circle.count == 2 else { return nil }
        return [0.5 + (circle[0] - center[0]) / scale[0], 0.5 - (circle[1] - center[1]) / scale[1]]
    }

    func uv(_ u: Float, _ v: Float) -> SIMD2<Float> {
        [(u - 0.5) * scale[0] + center[0], (0.5 - v) * scale[1] + center[1]]
    }
}
