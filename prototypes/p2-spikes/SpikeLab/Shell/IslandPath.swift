// The world map as floating islands on your Flame's level path (decision 189, plan docs/plan-2.0/p36-map-islands.md):
// what the map shows, worked out from your record. Each stepping stone is one of your Flame's levels; each world's
// island sits on the path at its level (RealmID.islandLevel); your Flame stands on the stone of its level. The map's
// look is Codex's (IslandMapView); this file is only the rules.
import Foundation

struct IslandPath: Equatable {
    enum StoneState: Equatable { case passed, current, ahead }
    struct Stone: Equatable, Identifiable {
        let level: Int
        let state: StoneState
        /// The world whose island this stone belongs to (its island's level), if any.
        let island: RealmID?
        var id: Int { level }
    }
    enum IslandState: Equatable {
        case open                                   // yours: tap to fly there
        case buyable(price: Int, affordable: Bool)  // the next world, and your Flame has reached it: buy it with Embers
        case toReach(level: Int)                    // the next world, but your Flame hasn't reached its island yet
        case waiting(level: Int)                    // further along the road: it waits for the worlds before it
        case sealed                                 // not in the game yet (the Veil, or a world not painted yet)
    }
    struct Island: Equatable, Identifiable {
        let realm: RealmID
        let level: Int
        let state: IslandState
        var id: RealmID { realm }
    }

    /// Bottom (the Sanctuary, level 1) to top (the Veil).
    let islands: [Island]
    /// Level 1 up to the last island's level (or a little past your Flame, if it has gone further).
    let stones: [Stone]
    /// Your Flame's level, and the stone it stands on.
    let flameLevel: Int
    var flameStone: Int { min(flameLevel, stones.last?.level ?? 1) }

    static func make(flameLevel: Int, open: Set<RealmID>, built: Set<RealmID>, nextToBuy: RealmID?, embers: Int,
                     order: [RealmID] = roadOrder) -> IslandPath {
        let islands = order.map { r -> Island in
            let state: IslandState
            if open.contains(r) { state = .open }
            else if r == .veil || !built.contains(r) { state = .sealed }
            else if r == nextToBuy {
                state = flameLevel >= r.islandLevel ? .buyable(price: r.price, affordable: embers >= r.price) : .toReach(level: r.islandLevel)
            } else { state = .waiting(level: r.islandLevel) }
            return Island(realm: r, level: r.islandLevel, state: state)
        }
        let last = max(order.map(\.islandLevel).max() ?? 1, flameLevel)
        let byLevel = Dictionary(order.map { ($0.islandLevel, $0) }, uniquingKeysWith: { a, _ in a })
        let stones = (1...last).map { n in
            Stone(level: n, state: n < flameLevel ? .passed : n == flameLevel ? .current : .ahead, island: byLevel[n])
        }
        return IslandPath(islands: islands, stones: stones, flameLevel: flameLevel)
    }
}

extension ShellModel {
    /// The map's path now, from your record. (Test: `-maplevel N` shows the Flame at level N, nothing saved.)
    var islandPath: IslandPath {
        let j = journey, a = CommandLine.arguments
        let level = a.firstIndex(of: "-maplevel").flatMap { a.indices.contains($0 + 1) ? Int(a[$0 + 1]) : nil } ?? j.flameLevel
        return IslandPath.make(flameLevel: level, open: open, built: ShellModel.builtRealms,
                               nextToBuy: j.nextToBuy(among: ShellModel.builtRealms), embers: j.embers)
    }
}
