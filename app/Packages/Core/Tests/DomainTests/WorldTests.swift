import Foundation
import Testing
@testable import Domain

struct WorldTests {
    private func state(depth: [Pillar: Double] = [:], active: Int = 0, witnessed: Set<String> = []) -> DerivedState {
        DerivedState(today: LocalDate(year: 2026, month: 10, day: 1), bornDay: nil, daysSinceBirth: 0, ascent: 1, vitality: 1,
                     comebackActive: false, depth: depth, recentMix: [:], activeDays: active, todayCompletion: 0,
                     todayPlan: [], completedToday: [], completedEver: [], witnessed: witnessed)
    }
    let grove = Location(id: "grove", realm: "Whispering Grove", unlock: .journeyStep(2))
    let library = Location(id: "library", realm: "Library of Embers", unlock: .all([.pillarDepth(.mind, 20), .activeDays(10)]))

    @Test func aLocationOpensOnlyByLiving() {
        #expect(!World.isOpen(grove, state: state(), journeyStep: 1))
        #expect(World.isOpen(grove, state: state(), journeyStep: 2))
    }

    @Test func combinedConditionsNeedEveryPart() {
        #expect(!World.isOpen(library, state: state(depth: [.mind: 25], active: 5), journeyStep: 0))
        #expect(World.isOpen(library, state: state(depth: [.mind: 25], active: 10), journeyStep: 0))
    }

    @Test func anOpenedLocationIsNeverTakenBack() {
        // Depth can't fall, but even if conditions stopped holding, a celebrated location stays open.
        let owned = state(witnessed: [World.openedKey("library")])
        #expect(World.isOpen(library, state: owned, journeyStep: 0))
    }

    @Test func newlyOpenedListsOnlyUncelebratedEarnedPlaces() {
        let s = state(witnessed: [World.openedKey("grove")])
        #expect(World.newlyOpened([grove, library], state: s, journeyStep: 3).isEmpty)
        #expect(World.newlyOpened([grove], state: state(), journeyStep: 3).map(\.id) == ["grove"])
    }
}
