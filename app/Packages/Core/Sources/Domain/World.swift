import Foundation

/// The world (chapter 29 §B.2): locations that open only by living. Pure and deterministic.
public indirect enum Condition: Sendable, Equatable {
    case always
    case journeyStep(Int)
    case pillarDepth(Pillar, Double)
    case activeDays(Int)
    case witnessed(String)
    case all([Condition])
    case any([Condition])

    public func isMet(_ s: DerivedState, journeyStep: Int) -> Bool {
        switch self {
        case .always: true
        case .journeyStep(let n): journeyStep >= n
        case .pillarDepth(let p, let min): (s.depth[p] ?? 0) >= min
        case .activeDays(let n): s.activeDays >= n
        case .witnessed(let key): s.witnessed.contains(key)
        case .all(let cs): cs.allSatisfy { $0.isMet(s, journeyStep: journeyStep) }
        case .any(let cs): cs.contains { $0.isMet(s, journeyStep: journeyStep) }
        }
    }
}

public struct Location: Sendable, Equatable, Identifiable {
    public let id: String
    public let realm: String
    public let unlock: Condition
    public init(id: String, realm: String, unlock: Condition) { self.id = id; self.realm = realm; self.unlock = unlock }
}

public enum World {
    /// Entry keys (P, momentWitnessed): opening a location is celebrated once and owned forever.
    public static func openedKey(_ id: String) -> String { "location:\(id)" }
    public static func visitedKey(_ id: String) -> String { "visit:\(id)" }

    /// Owned = already celebrated (never revoked), or earned now (conditions met).
    public static func isOpen(_ loc: Location, state: DerivedState, journeyStep: Int) -> Bool {
        state.witnessed.contains(openedKey(loc.id)) || loc.unlock.isMet(state, journeyStep: journeyStep)
    }

    /// Newly earned locations not yet celebrated, in map order.
    public static func newlyOpened(_ locations: [Location], state: DerivedState, journeyStep: Int) -> [Location] {
        locations.filter { !state.witnessed.contains(openedKey($0.id)) && $0.unlock.isMet(state, journeyStep: journeyStep) }
    }
}
