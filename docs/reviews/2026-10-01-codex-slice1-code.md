**Critical**

- [AppModel.swift:35](/Users/mathis/AI%20Projects/Life%20Gamified/app/LifeGamified/App/AppModel.swift:35), lines 94–102 — Storage failures silently become an empty record or an in-memory database; failed writes still return “successful” completion outcomes. Users can lose new progress on restart or be shown birth again despite existing history. **Fix:** propagate storage errors, preserve the last readable state, disable recording until persistence recovers, and never silently substitute an in-memory store.

**Important**

- [AppModel.swift:208](/Users/mathis/AI%20Projects/Life%20Gamified/app/LifeGamified/App/AppModel.swift:208) — Keeping Today open across 04:00 leaves yesterday’s slots loaded. Completing one writes yesterday’s occurrence key onto today’s record, producing incorrect completion and growth. Swapping and Ritual completion have the same stale-state risk. **Fix:** refresh/deal at the boundary and before mutations; capture one timestamp and reject stale cards.

- [Haptics.swift:13](/Users/mathis/AI%20Projects/Life%20Gamified/app/LifeGamified/Experience/Haptics.swift:13) — The reset callback accesses MainActor-isolated state from Core Haptics’ internal queue. With Swift 6 isolation checks, a hardware-engine reset can crash. **Fix:** make the callback explicitly `@Sendable`, then hop into `Task { @MainActor in … }`; clear invalidated players before restarting.

- [LifeGamifiedApp.swift:13](/Users/mathis/AI%20Projects/Life%20Gamified/app/LifeGamified/App/LifeGamifiedApp.swift:13) — Birth is considered finished as soon as `flameBorn` exists. Terminating during dawn, before choosing a Path, permanently skips onboarding on relaunch; Today has no Path and no first spark. **Fix:** persist or derive onboarding progress and resume the first unfinished step.

- [GrowthEngine.swift:75](/Users/mathis/AI%20Projects/Life%20Gamified/app/Packages/Core/Sources/Domain/GrowthEngine.swift:75) — Fill excludes slots from **every** contract, so adding a contract can retract earned growth, violating chapter 04 B.1. Example: contract `[a:1,b:1]`, completed `a` plus extra `x:1` scores 100%; adding `[x:1,y:3]` reduces it to 50%. **Fix:** calculate non-scheduled fill separately for each contract, then take the maximum score.

- [AppModel.swift:292](/Users/mathis/AI%20Projects/Life%20Gamified/app/LifeGamified/App/AppModel.swift:292) — Developer time travel writes simulated plans/actions into the real permanent record. “Back to real time” hides future progress until those dates arrive; future Paths also remain active because their projection ignores the date. **Fix:** use a separate simulation store and clock, leaving the real record untouched.

- [AppModel.swift:178](/Users/mathis/AI%20Projects/Life%20Gamified/app/LifeGamified/App/AppModel.swift:178) — Hidden Sparks resolve through `Catalog.spark`, which searches only ordinary Sparks. Users see “Today’s Spark” without an actual challenge but can claim its growth. **Fix:** use the existing `Catalog.anySpark` lookup.

**Minor**

- [AppModel.swift:264](/Users/mathis/AI%20Projects/Life%20Gamified/app/LifeGamified/App/AppModel.swift:264) — Chronicle counts raw completions, including undone actions and duplicates. **Fix:** apply the engine’s correction resolution and occurrence deduplication before summarizing.

- [AppModel.swift:215](/Users/mathis/AI%20Projects/Life%20Gamified/app/LifeGamified/App/AppModel.swift:215) — Comeback celebration requires Vitality below 0.5, suppressing qualifying three-day returns; no witnessed marker prevents replay after undo/recompletion. **Fix:** detect the specified first comeback completion and persist/check `comeback:{livedDay}`.

`swift test` could not run: sandbox denied compiler/cache writes. Python reference vectors passed. No outbound networking or personal-data logging found in the reviewed sources. No files modified.