import Testing
@testable import Domain

struct CharacterTests {
    @Test func everyFlameIsBornAsASpark() {
        #expect(CharacterStage.earned(activeDays: 0, totalDepth: 0) == .spark)
    }

    @Test func aWeekOfLivingMakesAFlame() {
        #expect(CharacterStage.earned(activeDays: 7, totalDepth: 5) == .flame)
    }

    @Test func evolutionNeedsTimeLivedNotJustEffort() {
        #expect(CharacterStage.earned(activeDays: 20, totalDepth: 999) == .flame)
        #expect(CharacterStage.earned(activeDays: 60, totalDepth: 120) == .blaze)
        #expect(CharacterStage.earned(activeDays: 300, totalDepth: 800) == .kindled)
    }

    @Test func stagesAreCelebratedOneAtATimeAndOwnedForever() {
        #expect(CharacterStage.pending(activeDays: 70, totalDepth: 200, witnessed: []) == .flame)
        #expect(CharacterStage.pending(activeDays: 70, totalDepth: 200, witnessed: [CharacterStage.flame.key]) == .blaze)
        let owned: Set<String> = [CharacterStage.flame.key, CharacterStage.blaze.key]
        #expect(CharacterStage.pending(activeDays: 70, totalDepth: 200, witnessed: owned) == nil)
        #expect(CharacterStage.owned(witnessed: owned) == .blaze)
    }
}
