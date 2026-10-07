// The app shell (decision 105): one journey you move through — the intro, home (the cockpit), the road map,
// the worlds. Prototype state only; the real record and engine take over when this moves into app/ (P3).
import SwiftUI
import RealityKit

enum Screen: Equatable { case intro, home, map, realm(RealmID) }

enum RealmID: String, CaseIterable, Identifiable {
    case sanctuary, grove, stillwater, highlands, library, wilds, forge, veil
    var id: String { rawValue }
    /// Embers to open this world (decision 136): about a week of living for the first, more for each after.
    var price: Int {
        switch self {
        case .sanctuary, .grove: 0
        case .stillwater: 150
        case .highlands: 250
        case .library: 350
        case .wilds: 450
        case .forge: 550
        case .veil: 1000
        }
    }

    var name: String {
        switch self {
        case .sanctuary: "The Sanctuary"
        case .grove: "The Whispering Grove"
        case .stillwater: "The Stillwater"
        case .highlands: "The Ascent Highlands"
        case .library: "The Library of Embers"
        case .wilds: "The Wilds"
        case .forge: "Forge Mountain"
        case .veil: "Beyond the Veil"
        }
    }
    var pillar: String {
        switch self {
        case .sanctuary: "Home"
        case .grove: "Heart"
        case .stillwater: "Spirit"
        case .highlands: "Body"
        case .library: "Mind"
        case .wilds: "World"
        case .forge: "Craft"
        case .veil: "???"
        }
    }
    var symbol: String {
        switch self {
        case .sanctuary: "flame.fill"
        case .grove: "heart.fill"
        case .stillwater: "drop.fill"
        case .highlands: "figure.walk"
        case .library: "book.fill"
        case .wilds: "leaf.fill"
        case .forge: "hammer.fill"
        case .veil: "sparkles"
        }
    }
    var color: Color {
        switch self {
        case .sanctuary: Color(red: 1.0, green: 0.7, blue: 0.3)
        case .grove: Color(red: 0.95, green: 0.55, blue: 0.62)
        case .stillwater: Color(red: 0.75, green: 0.82, blue: 0.95)
        case .highlands: Color(red: 1.0, green: 0.55, blue: 0.2)
        case .library: Color(red: 0.5, green: 0.7, blue: 1.0)
        case .wilds: Color(red: 0.55, green: 0.85, blue: 0.45)
        case .forge: Color(red: 0.85, green: 0.6, blue: 0.35)
        case .veil: Color(red: 0.75, green: 0.6, blue: 1.0)
        }
    }
    /// Where it sits on Codex's world map (pixels of the 803 × 1958 painting).
    var mapPoint: CGPoint {
        switch self {
        case .sanctuary: CGPoint(x: 400, y: 1555)
        case .grove: CGPoint(x: 160, y: 905)
        case .stillwater: CGPoint(x: 690, y: 1005)
        case .highlands: CGPoint(x: 610, y: 640)
        case .library: CGPoint(x: 170, y: 470)
        case .wilds: CGPoint(x: 680, y: 400)
        case .forge: CGPoint(x: 450, y: 225)
        case .veil: CGPoint(x: 560, y: 70)
        }
    }
    /// What opens it (shown on locked nodes; Act I and the plan's conditions).
    var opensWhen: String {
        switch self {
        case .sanctuary: ""
        case .grove: "3 days lived"
        case .stillwater: "Spirit light"
        case .highlands: "Body light"
        case .library: "Mind light"
        case .wilds: "World light"
        case .forge: "30 days lived"
        case .veil: "three Beacons"
        }
    }
}

struct Call: Identifiable, Equatable {
    let id: String
    let title: String, detail: String, symbol: String
    let realm: RealmID
    var done = false
    /// Taken from the satchel for today: it then waits in the Sanctuary as an object.
    var chosen = false
    /// How long it takes, shown in the journal.
    var minutes: Int = 5
    /// Life Reset-style detail (decision 134): how often, how hard, and a count to reach inside the quest.
    var frequency = "Daily"
    var difficulty = "Easy"
    var target = 1
    var unit = ""
    var progress = 0
    /// Why the Companion suggests it (shown on the suggested card).
    var reason = ""
    var skipped = false
    var counted: Bool { target > 1 }
    /// The painted object it becomes in the world (Codex's props, iteration 2).
    var prop: String {
        if symbol == "sparkle" { return "prop-scroll" }
        switch realm {
        case .grove: return "prop-lantern"
        case .stillwater: return "prop-bloom"
        case .library: return "prop-scroll"
        default: return "prop-crystal"
        }
    }
}

@MainActor @Observable
final class ShellModel {
    var screen: Screen = ShellModel.realmArg != nil ? .home : (CommandLine.arguments.contains("-grove") ? .realm(.grove) : CommandLine.arguments.contains("-map") ? .map : (CommandLine.arguments.contains("-skipintro") ? .home : .intro))
    private static var realmArg: RealmID? {
        guard let i = CommandLine.arguments.firstIndex(of: "-realm"), i + 1 < CommandLine.arguments.count else { return nil }
        return RealmID(rawValue: CommandLine.arguments[i + 1])
    }
    var interest: String = "Be closer to people I love"
    /// Open realms: home, the Grove (Act I), and every realm whose pillar you've lit with a real action (and whose world
    /// is painted). Beyond the Veil never opens in the prototype. (-allopen: everything painted, for testing.)
    var open: Set<RealmID> {
        // Decision 136: worlds are bought with Embers earned by living. The beta opens every world.
        var s: Set<RealmID> = [.sanctuary, .grove]
        for r in Self.builtRealms where Self.beta || CommandLine.arguments.contains("-allopen") || journey.bought.contains(r.rawValue) { s.insert(r) }
        return s
    }
    /// A daily pouch waiting to be collected on home (its Embers are already counted; collecting makes them fly).
    var dailyGift = 0
    var newHere: Set<RealmID> = [.grove]              // the glow + badge: "something new waits here"
    var flameAt: RealmID = .sanctuary
    var calls: [Call] = []
    var light: Int = 0                                // today's light sent into the world
    /// What you've lived: the Book writes itself from it; Your Flame sums it up (decisions 128–129).
    let journey = Journey()
    /// The worlds, built once and kept alive: going back to a screen shows it instantly instead of reloading its
    /// paintings (that reload was the biggest lag). One engine (RealmScene) runs every realm.
    let sanctuary = SanctuaryScene()
    let mapScene = MapScene()
    @ObservationIgnored private var realmScenes: [RealmID: RealmScene] = [:]
    func realmScene(_ r: RealmID) -> RealmScene {
        if let s = realmScenes[r] { return s }
        let s = RealmScene(realm: r); realmScenes[r] = s; return s
    }
    var grove: RealmScene { realmScene(.grove) }
    /// Realms that have their painted world in the app (the others only exist on the map for now).
    /// Every world open for Mathis's testing (2026-10-06: "make sure I have access to all worlds"); -locked shows
    /// the real flow, where Embers buy the next world on the road, one after another (decision 144).
    static let beta = !CommandLine.arguments.contains("-locked")
    static let builtRealms: Set<RealmID> = {
        let all: [RealmID] = [.grove, .stillwater, .highlands, .library, .wilds, .forge]
        var s: Set<RealmID> = [.grove]
        for r in all where Bundle.main.url(forResource: r.rawValue + "-layout", withExtension: "json") != nil { s.insert(r) }
        return s
    }()
    /// A sheet (satchel, Book, Your Flame, a quest card) covers the world: its per-frame work pauses so scrolling
    /// gets the whole phone (the water, fire and sky keep moving: they run on the graphics chip).
    var overlayOpen = false
    /// A full sheet covers the world: the 3D stops rendering (a soft blurred picture of the world shows behind the
    /// sheet instead), so the sheet gets the whole graphics chip: measured 40 → 60 fps while scrolling (2026-10-05).
    var worldPaused = false {
        didSet {
            // Nothing is switched off (re-preparing a world cost 1–2 s at 20 fps): the camera looks into empty space.
            if worldPaused, let c = activeCamera { c.look(at: [0, 5000, -1], from: [0, 5000, 0], relativeTo: c.parent) }
        }
    }
    private var activeCamera: Entity? {
        switch activeWorld { case .sanctuary: sanctuary.camera; case .map: mapScene.camera; case .realm(let r): realmScenes[r]?.camera }
    }
    var sanctuaryBuilt = false
    var mapBuilt = false
    var realmsBuilt: Set<RealmID> = []
    var groveBuilt: Bool { realmsBuilt.contains(.grove) }
    /// One 3D view for the whole app (like a game): every world lives under this root; switching screens only
    /// shows one and hides the others, so nothing is ever rebuilt or re-created.
    @ObservationIgnored let worldRoot = Entity()
    @ObservationIgnored var updates: EventSubscription?
    @ObservationIgnored private var builds: [World: Task<Void, Never>] = [:]
    enum World: Hashable { case sanctuary, map, realm(RealmID) }
    var activeWorld: World {
        switch screen { case .map: .map; case .realm(let r): .realm(r); default: .sanctuary }
    }

    /// Builds a world once (or waits for the build already running), then parks it hidden under the root.
    func ensure(_ w: World) async {
        if let t = builds[w] { await t.value; return }
        let t = Task { @MainActor in
            let t0 = CACurrentMediaTime()
            defer { if PerfProbe.on { print(String(format: "BUILD %@ %.0f ms (main thread)", "\(w)", (CACurrentMediaTime() - t0) * 1000)) } }
            switch w {
            case .sanctuary where !sanctuaryBuilt:
                if (try? await sanctuary.build()) != nil { place(sanctuary.root, sanctuary.camera, slot: 0); sanctuaryBuilt = true }
            case .map where !mapBuilt:
                let lastOpen = roadIndex(roadOrder.last { open.contains($0) } ?? .sanctuary)
                if (try? await mapScene.build(open: open, flameAt: flameAt, lastOpenRoadIndex: lastOpen, ember: emberID)) != nil {
                    place(mapScene.root, mapScene.camera, slot: 1); mapBuilt = true
                }
            case .realm(let r) where !realmsBuilt.contains(r):
                let sc = realmScene(r)
                if (try? await sc.build()) != nil { place(sc.root, sc.camera, slot: 2 + (RealmID.allCases.firstIndex(of: r) ?? 0)); realmsBuilt.insert(r) }
            default: break
            }
        }
        builds[w] = t
        await t.value
    }

    /// Shows the world of the current screen (instant: the others are only hidden).
    func showActive() { PerfProbe.measure("showActive") { showActiveNow() } }
    /// Each world lives in its own place in space, always switched on (so it never has to be re-prepared);
    /// only the camera of the world on screen is on, and the others are simply out of sight.
    private func place(_ root: Entity, _ cam: Entity, slot: Int) {
        PixelMode.apply(to: root, on: PixelMode.on)        // the pixel look, if chosen
        root.position = [Float(slot) * 500, 0, 0]
        cam.isEnabled = false
        worldRoot.addChild(root)
    }
    private func showActiveNow() {
        let a = activeWorld
        sanctuary.camera.isEnabled = a == .sanctuary && sanctuaryBuilt
        mapScene.camera.isEnabled = a == .map && mapBuilt
        for (r, sc) in realmScenes { sc.camera.isEnabled = a == .realm(r) && realmsBuilt.contains(r) }
        if !isBuilt(a) { Task { @MainActor in await ensure(a); showActive() } }
    }
    /// Switches every built world (and your Spark) between the painted and the pixel look, live.
    var pixel: Bool = PixelMode.on
    func setPixel(_ on: Bool) {
        PixelMode.on = on; pixel = on
        if sanctuaryBuilt { PixelMode.apply(to: sanctuary.root, on: on) }
        if mapBuilt { PixelMode.apply(to: mapScene.root, on: on) }
        for r in realmsBuilt { PixelMode.apply(to: realmScene(r).root, on: on) }
    }
    func isBuilt(_ w: World) -> Bool {
        switch w { case .sanctuary: sanctuaryBuilt; case .map: mapBuilt; case .realm(let r): realmsBuilt.contains(r) }
    }

    /// Every frame: only the world on screen moves.
    @ObservationIgnored private var tickCost: (sum: Double, n: Int, worst: Double) = (0, 0, 0)
    func tick(_ dt: Float) {
        let t0 = CACurrentMediaTime()
        defer {
            if CommandLine.arguments.contains("-perf") {
                let c = (CACurrentMediaTime() - t0) * 1000
                tickCost.sum += c; tickCost.n += 1; tickCost.worst = max(tickCost.worst, c)
                if tickCost.n >= 120 {
                    print(String(format: "TICK avg %.2f ms worst %.2f ms", tickCost.sum / Double(tickCost.n), tickCost.worst))
                    tickCost = (0, 0, 0)
                }
            }
        }
        if overlayOpen { return }
        // After a slow frame, never take one giant step: springs (the camera, your Spark) would overshoot and swing.
        // Long gaps are walked through in small steps instead, so motion stays smooth whatever happens.
        var rest = min(dt, 0.25)
        while rest > 0.0001 {
            let step = min(rest, 1.0 / 60)
            rest -= step
            advance(step)
        }
    }

    private func advance(_ dt: Float) {
        switch activeWorld {
        case .sanctuary: if sanctuaryBuilt { sanctuary.update(dt: dt) }
        case .map: if mapBuilt { mapScene.update(dt: dt) }
        case .realm(let r): if realmsBuilt.contains(r) { realmScene(r).update(dt: dt) }
        }
    }

    /// The core worlds (home, the map, the Grove) are all ready: nothing loads while you're using the app.
    var coreReady = false
    /// Prepares the map and the Grove (at launch behind the dusk veil, or during the intro's "preparing" moment), so
    /// building never competes with what you see (measured: 30 fps for seconds when it happened during home).
    func preloadCore() async {
        await ensure(.map)
        await warm(mapScene.root)
        await ensure(.realm(.grove))
        await warm(realmScene(.grove).root)
        coreReady = true
    }
    /// A world built but never drawn pays its whole first-draw cost (shaders, its big painting sent to the graphics
    /// chip) the moment it first shows: the map froze 1.7 s on its first opening. So right after building it, a
    /// microscopic copy of it (smaller than a pixel) is drawn in front of the camera on screen for half a second,
    /// out of sight; its first real opening is then instant.
    func warm(_ root: Entity) async {
        guard let cam = activeCamera else { return }
        let ghost = root.clone(recursive: true)
        ghost.position = [0, 0, -0.5]
        ghost.scale = .init(repeating: 0.0002)
        cam.addChild(ghost)
        try? await Task.sleep(for: .milliseconds(500))
        ghost.removeFromParent()
    }
    func preloadLater() {}
    /// The ember you chose in the introduction: your Spark burns in its color (Mathis, 2026-10-03).
    var emberID: String = UserDefaults.standard.string(forKey: "ember.id") ?? "craft"
    func setEmber(_ id: String) { emberID = id; UserDefaults.standard.set(id, forKey: "ember.id"); SparkTint.warmUp(ember: id) }
    /// Set when a realm is entered by the map's dive: the realm then opens out of the dive's light.
    var arrivingByDive = false
    /// The guided tour right after the introduction: the Sanctuary's options, the world map, the Grove.
    enum TourStep { case satchel, world, map, grove }
    var tour: TourStep?

    init() {
        SparkTint.warmUp(ember: UserDefaults.standard.string(forKey: "ember.id") ?? "craft")
        for e in Set(Friend.samples.map(\.ember)) { SparkTint.warmUp(ember: e) }      // friends' Sparks, ready too
        if let i = CommandLine.arguments.firstIndex(of: "-ember"), i + 1 < CommandLine.arguments.count { setEmber(CommandLine.arguments[i + 1]) }   // (test)
        makeCalls()
        if journey.checkIn() && journey.bornOn != nil { dailyGift = Journey.dailyGift }   // the daily pouch (decision 141)
        journey.grant(200, id: "beta-purse")              // the test's starter purse: enough to buy a world right away
        if CommandLine.arguments.contains("-quests") { for id in ["a", "c", "d"] { toggleChosen(id) } }   // (test: three taken)
    }

    func chose(_ interest: String) {
        self.interest = interest
        makeCalls()
    }

    func makeCalls() {
        let first: Call = switch interest {
        case "Read again": Call(id: "a", title: "Ten pages", detail: "Read ten pages of any book you like.", symbol: "book.fill", realm: .library, minutes: 15, difficulty: "Medium", target: 10, unit: "pages", reason: "You said you want to read again. Ten pages a day is about a book a month.")
        case "Find calm": Call(id: "a", title: "Three slow breaths", detail: "Sit, close your eyes, breathe in for four, out for six.", symbol: "drop.fill", realm: .stillwater, minutes: 2, target: 3, unit: "breaths", reason: "Slow breathing (longer out than in) calms the body within a minute.")
        case "Move a little every day": Call(id: "a", title: "A moment outside", detail: "Walk for ten minutes, at an easy pace.", symbol: "figure.walk", realm: .highlands, minutes: 10, target: 10, unit: "min", reason: "Ten easy minutes a day is where lasting movement habits start.")
        case "Make something / focus": Call(id: "a", title: "One focused block", detail: "Twenty minutes on one thing that matters to you.", symbol: "hammer.fill", realm: .forge, minutes: 20, difficulty: "Medium", target: 20, unit: "min", reason: "One protected block a day beats long sessions you can't keep up.")
        case "Spend time in nature": Call(id: "a", title: "Notice something alive", detail: "Step outside and find one living thing to look at closely.", symbol: "leaf.fill", realm: .wilds, minutes: 5, reason: "A few minutes outside, really looking, lifts the mood for hours.")
        default: Call(id: "a", title: "A lantern for someone", detail: "Tell someone you love one thing you admire about them.", symbol: "heart.fill", realm: .grove, reason: "You chose to be closer to the people you love. One kind word today is a lantern relit.")
        }
        // The day's quests, offered in the satchel (iteration 2): you choose up to three; they wait in the world.
        calls = [first,
                 Call(id: "b", title: "A small challenge", detail: "A little fox is curious about kindness: thank someone who rarely hears it.", symbol: "sparkle", realm: .grove, minutes: 3, frequency: "Today's Spark", difficulty: "Medium"),
                 Call(id: "c", title: "A quiet moment", detail: "Two minutes of silence by the hearth before bed.", symbol: "moon.fill", realm: .stillwater, minutes: 2, target: 2, unit: "min"),
                 Call(id: "d", title: "Ten minutes outside", detail: "Step out and walk at an easy pace. Notice the sky.", symbol: "figure.walk", realm: .highlands, minutes: 10, target: 10, unit: "min"),
                 Call(id: "e", title: "One page", detail: "Read a single page of something you've been meaning to read.", symbol: "book.fill", realm: .library, minutes: 5),
                 Call(id: "f", title: "Twenty push-ups", detail: "In as many sets as you need. Rest between them.", symbol: "figure.strengthtraining.traditional", realm: .highlands, minutes: 6, difficulty: "Hard", target: 20, unit: "reps")]
    }

    static let maxChosen = 3
    var chosenCount: Int { calls.filter { $0.chosen && !$0.done }.count }
    func toggleChosen(_ id: String) {
        guard let i = calls.firstIndex(where: { $0.id == id }), !calls[i].done else { return }
        if calls[i].chosen {
            // Put back in the satchel: it goes to the end, so the quests still out keep their spots.
            var c = calls.remove(at: i); c.chosen = false; calls.append(c)
        }
        else if chosenCount < Self.maxChosen { calls[i].chosen = true }
    }

    @discardableResult
    func complete(_ id: String) -> DeedOutcome? {
        guard let i = calls.firstIndex(where: { $0.id == id }) else { return nil }
        calls[i].done = true
        calls[i].progress = calls[i].target
        light += 1
        return journey.did(calls[i].title, detail: calls[i].detail, realm: calls[i].realm, minutes: calls[i].minutes)
    }
    /// Progress inside a quest (reps, pages, minutes): one step further.
    func step(_ id: String, by n: Int = 1) {
        guard let i = calls.firstIndex(where: { $0.id == id }), !calls[i].done else { return }
        calls[i].progress = min(calls[i].target, calls[i].progress + n)
    }
    /// An honest skip: today it's not for you. Never punished; it goes back in the satchel, under "Skipped".
    func skip(_ id: String) {
        guard let i = calls.firstIndex(where: { $0.id == id }), !calls[i].done else { return }
        calls[i].skipped = true; calls[i].chosen = false
        journey.skip(calls[i].title)
    }
    func unskip(_ id: String) { if let i = calls.firstIndex(where: { $0.id == id }) { calls[i].skipped = false } }

    /// (-perf) When the last screen change was asked for, to log how long until the new world's first frame.
    @ObservationIgnored var tappedAt: CFTimeInterval = 0
    func firstFrame(_ what: String) {
        guard tappedAt > 0, CommandLine.arguments.contains("-perf") else { return }
        print(String(format: "REACT %@ first frame after %.0f ms", what, (CACurrentMediaTime() - tappedAt) * 1000)); tappedAt = 0
    }
    func go(_ s: Screen) {
        tappedAt = CACurrentMediaTime()
        defer {
            if s == .map, mapBuilt { mapScene.arrive(at: flameAt); mapScene.refresh(open: open) }   // over where you are; newly opened realms wake
            if case .realm(let r) = s, realmsBuilt.contains(r) { realmScene(r).focus = nil; realmScene(r).panTarget = .zero }
            showActive()
            firstFrame(isBuilt(activeWorld) ? "\(activeWorld) (shown)" : "\(activeWorld) (building)")
        }
        if case .realm(let r) = s { newHere.remove(r); flameAt = r; journey.entered(r) }
        if s == .map { journey.sawTheWorld() }
        if s == .home { flameAt = .sanctuary }
        screen = s
    }
}
