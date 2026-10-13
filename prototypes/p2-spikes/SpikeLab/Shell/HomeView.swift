// Home, the cockpit (decision 105): your Flame on the stone circle, today's calls floating by the hearth like the
// UI kit (style anchor), the light flying from a finished call to your Flame, and a clear bar: the World, the Book,
// your Flame. A hint always points to where something new waits.
import SwiftUI
import RealityKit

struct HomeView: View {
    let model: ShellModel
    /// Which world you're in (Mathis: the same interface in every world; only the world changes).
    var world: RealmID = .sanctuary
    private var scene: LivingWorld { world == .sanctuary ? model.sanctuary : model.realmScene(world) }
    private var realmScene: RealmScene? { world == .sanctuary ? nil : model.realmScene(world) }
    private var built: Bool { world == .sanctuary ? model.sanctuaryBuilt : model.realmsBuilt.contains(world) }
    @State private var bandTop: CGFloat = 0          // the free space around the Flame (162): its top…
    @State private var bandBottom: CGFloat = 0       // …and its bottom (the quests)
    @State private var focused: Spot?
    @State private var reward: DeedOutcome?
    @State private var backdrop: Double = 0           // the blurred world behind full sheets (0 = live world)
    private var covered: Bool { satchelOpen || bookOpen || flameOpen }
    @State private var meter = FrameMeter()
    @State private var director: AliveDirector?
    @State private var open: Call?
    @State private var strand: (from: CGPoint, start: Date)?
    @State private var toast: String?
    @State private var dragStartPan: SIMD2<Float>?
    @State private var barTaps: [String: Int] = [:]
    @State private var coinTarget = CGPoint(x: 320, y: 130)     // where the Embers counter is (coins fly there)
    @State private var burst: CoinFlight.Burst?
    @State private var shownEmbers: Int?                       // the counter lags while coins are in the air
    @State private var burstAmount = 0
    @State private var satchelOpen = false
    @State private var bookOpen = CommandLine.arguments.contains("-book")
    @State private var flameOpen = CommandLine.arguments.contains("-flamesheet")
    @State private var fullSize: CGSize = .zero

    private var questSpots: [SIMD2<Float>] { scene.questSpots }
    /// Quests now live in the list on home (QuestBoard); the objects in the world are off.
    static let questObjects = false
    private var today: [Call] { model.calls.filter { $0.chosen && !$0.skipped }.sorted { !$0.done && $1.done } }
    private var chosen: [Call] { model.calls.filter { $0.chosen && !$0.done } }
    /// Each quest keeps its spot for the day (finishing one never moves the others).
    private func spotFor(_ call: Call) -> SIMD2<Float> {
        let i = model.calls.filter { $0.chosen }.firstIndex { $0.id == call.id } ?? 0
        return questSpots[i % questSpots.count]
    }

    var body: some View {
        let _ = PerfProbe.body("Home")
        GeometryReader { geo in
            ZStack {
                // The Sanctuary itself is drawn by the app's one 3D view, underneath (WorldLayer): this layer only
                // catches touches (tap your Spark, look around).
                // Tap the world itself: a realm's places (its Keeper, its landmarks) answer where they're painted;
                // anywhere else, your Spark reacts. No floating markers (Mathis).
                GeometryReader { full in
                    Color.clear.contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { p in tappedWorld(at: p, in: full.size) }
                }
                .ignoresSafeArea()

                // The quests you took, waiting in the world as small glowing objects (they stay attached to their
                // spot when you look around). Tap one to do it.
                GeometryReader { full in
                    // Redrawn every frame only while quests are out and nothing covers them.
                    TimelineView(.animation(minimumInterval: nil, paused: (chosen.isEmpty && world == .sanctuary) || model.overlayOpen || !built)) { _ in
                        ZStack {
                            ForEach(Self.questObjects ? chosen : []) { call in
                                Button { withAnimation(.sheet) { open = call } } label: { QuestObject(call: call) }
                                    .position(scene.screenPoint(world: spotFor(call), in: full.size))
                                    .transition(.scale(scale: 0.2).combined(with: .opacity))
                            }
                        }
                        .frame(width: full.size.width, height: full.size.height)
                    }
                    .onAppear { fullSize = full.size }
                }
                .ignoresSafeArea()

                // The light flying from a finished quest to your Flame.
                if let s = strand {
                    // It flies frame by frame (time-based, no steps), easing in and out along an arc.
                    TimelineView(.animation) { tl in
                        let k = min(1, CGFloat(tl.date.timeIntervalSince(s.start) / 0.9)), t = k * k * (3 - 2 * k)
                        let to = scene.screenPoint(world: scene.flameUV, in: fullSize)
                        let p = CGPoint(x: s.from.x + (to.x - s.from.x) * t, y: s.from.y + (to.y - s.from.y) * t - sin(t * .pi) * 80)
                        Circle().fill(RadialGradient(colors: [.white, Color(red: 1, green: 0.8, blue: 0.4), .clear], center: .center, startRadius: 1, endRadius: 22))
                            .frame(width: 44, height: 44).scaleEffect(1 - 0.35 * t).position(p)
                    }
                    .ignoresSafeArea().allowsHitTesting(false)
                }

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    if let toast { Text(toast).font(.ui(14)).padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(.black.opacity(0.6))).foregroundStyle(.white).transition(.opacity).padding(.bottom, 8) }
                    // The quest sheet (decisions 157, 160, 161, after Finch): the bottom half always belongs to your
                    // quests, on a solid sheet; the world is the stage above it.
                    if model.tour != nil || focused != nil { hint }
                    VStack(spacing: 8) {
                        if model.tour == nil && focused == nil {
                            QuestBoard(calls: today, streakLine: streakLine(model.journey, light: model.light),
                                       add: { withAnimation(.sheet) { satchelOpen = true } },
                                       open: { c in withAnimation(.sheet) { open = c } },
                                       tick: { c, p in finish(c, size: geo.size, from: p) },
                                       streakOf: { model.journey.questStreak($0) }, alwaysOpen: true)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        cockpitBar
                    }
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { bandBottom = $0; placeFlame() }
                    .shadow(color: .black.opacity(0.7), radius: 3, y: 1)          // legible over the world
                    .padding(.top, 18).padding(.bottom, 2)
                    .background(alignment: .top) {
                        // Always open, and see-through (Mathis, decision 161): a light veil with rounded shoulders, the
                        // world (painted all the way down, 160) shows behind your quests; the cards themselves are solid.
                        UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                            .fill(Theme.floor.opacity(0.42))
                            .overlay(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                                .stroke(Theme.cream.opacity(0.12), lineWidth: 0.75))
                            .padding(.horizontal, -16).padding(.top, -4)
                            .ignoresSafeArea(edges: .bottom)
                    }
                }
                .padding(.horizontal, 16)
                .opacity(flameOpen || CommandLine.arguments.contains("-worldonly") ? 0 : 1)   // Your Flame is its own quiet page (-worldonly: test, the world alone)
                .animation(Motion.soft, value: flameOpen)

                if let s = focused { VStack { Spacer(); spotCard(s).padding(.horizontal, 16) } }
                if let call = open { card(call, size: geo.size) }
                if let r = reward { RewardBurst(outcome: r) { withAnimation { reward = nil } }.id(r.xp ^ r.streakAfter << 8 ^ r.attributeAfter << 16) }
                tourLayer
                if model.journey.roundComplete && model.dailyGift == 0 && model.tour == nil && built && open == nil && reward == nil && !(satchelOpen || bookOpen || flameOpen) {
                    let j = model.journey
                    RoundComplete(length: j.roundLength, lived: j.roundDaysLived, round: j.roundsDone + 1) { n in
                        withAnimation(.sheet) { j.startRound(n) }
                    }
                    .transition(.opacity)
                }
                if model.dailyGift > 0 && model.tour == nil && built && open == nil && !(satchelOpen || bookOpen || flameOpen) {
                    DailyPouch(amount: model.dailyGift) { pt in
                        let a = model.dailyGift
                        withAnimation(.easeOut(duration: 0.25)) { model.dailyGift = 0 }
                        coins(from: pt, amount: a)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                if let b = burst {
                    CoinFlight(burst: b, landed: { i in
                        let per = max(1, b.coins == 0 ? 0 : (burstAmount / b.coins))
                        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
                        shownEmbers = min(model.journey.embers, (shownEmbers ?? model.journey.embers) + per)
                    }, done: {
                        burst = nil
                        withAnimation(.spring(response: 0.3)) { shownEmbers = nil }      // exact total
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    })
                    .id(b.id)
                }
                // Behind full sheets: a soft, dimmed picture of this world; the live 3D pauses until they close.
                if backdrop > 0 {
                    Image(uiImage: UIImage(named: "backdrop-\(world.rawValue).jpg") ?? UIImage(named: "backdrop-sanctuary.jpg") ?? UIImage())
                        .resizable().scaledToFill().frame(width: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                                                          height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
                        .clipped().ignoresSafeArea().opacity(backdrop).allowsHitTesting(false)
                }
                if satchelOpen { QuestJournal(model: model, isOpen: $satchelOpen).transition(.move(edge: .bottom)) }
                if bookOpen { BookView(model: model, isOpen: $bookOpen, openOn: world.rawValue).transition(.move(edge: .bottom)) }
                if flameOpen { FlameSheet(model: model, isOpen: $flameOpen).transition(.move(edge: .bottom)) }
            }
            .simultaneousGesture(lookAround(geo.size), including: satchelOpen || bookOpen || flameOpen || open != nil ? .subviews : .all)
        }
        .onAppear {
            meter.start(); setUpWorld()
            if CommandLine.arguments.contains("-satchel") { satchelOpen = true }      // (test)
        }
        .onPreferenceChange(EmberTargetKey.self) { p in if let p { coinTarget = p } }
        .onReceive(NotificationCenter.default.publisher(for: .perfCommand)) { n in       // (-uitest)
            switch n.object as? String {
            case "satchel": withAnimation(.sheet) { satchelOpen = true }
            case "flame": withAnimation(.sheet) { flameOpen = true }
            case "book": withAnimation(.sheet) { bookOpen = true }
            case "close": withAnimation(.sheet) { satchelOpen = false; flameOpen = false; bookOpen = false }
            case "panL": scene.panTarget = [-scene.panLimit.x, 0]
            case "panR": scene.panTarget = [scene.panLimit.x, 0]
            case "pan0": scene.panTarget = .zero
            default: break
            }
        }
        .onChange(of: satchelOpen || bookOpen || flameOpen || open != nil) { _, covered in model.overlayOpen = covered }
        .onChange(of: covered) { _, isCovered in
            if isCovered {
                withAnimation(.easeOut(duration: 0.25)) { backdrop = 1 }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(260))
                    if covered { model.worldPaused = true }
                }
            } else {
                // The sheet slides away over the still picture first (cheap), then the world wakes under it and the
                // picture fades: waking the 3D during the slide is what dropped closing to ~39 fps.
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(240))
                    guard !covered else { return }
                    model.worldPaused = false
                    try? await Task.sleep(for: .milliseconds(50))         // its first frame lands under the picture
                    guard !covered else { return }
                    withAnimation(.easeOut(duration: 0.25)) { backdrop = 0 }
                }
            }
        }
        .onChange(of: built) { _, _ in setUpWorld() }
        .onDisappear { meter.stop(); director?.stop(); model.overlayOpen = false; model.worldPaused = false }
    }

    /// Your Spark in your color, the world bright, its little life director; then the other worlds preload.
    private func setUpWorld() {
        guard built, director == nil else { return }
        scene.hero.tint = SparkTint.shift(model.emberID)
        if world == .sanctuary {
            model.sanctuary.flameTarget = 1
            model.sanctuary.setVitality(1)
            model.preloadLater()
        } else if let rs = realmScene {
            // How awake the realm is comes from your real actions in its pillar (each relights a few of its lights).
            let lit = Float(model.journey.light(for: world)) * 3
            rs.heartDepth = max(rs.heartDepth, world == .grove ? max(6, lit) : lit)
        }
        let d = AliveDirector(seed: 5, meter: meter)
        d.attach(scene.hero, tempo: 0.55)
        director = d
    }

    /// A tap on the world: the nearest of the realm's places (within reach) tells its story; otherwise your Spark reacts.

    private func tappedWorld(at p: CGPoint, in size: CGSize) {
        if PerfProbe.on { print("TAP world at", p) }
        if focused != nil { unfocus(); return }
        let near = RealmContent.spots(world).map { s -> (Spot, CGFloat) in
            let c = scene.screenPoint(world: s.uv, in: size); return (s, hypot(p.x - c.x, p.y - c.y))
        }.min { $0.1 < $1.1 }
        if let (s, d) = near, d < 70 { focus(s) } else { director?.tapped() }
    }

    /// Explore a realm's place: the view glides toward it, staying inside the painting (no edge ever), and it
    /// tells its story.
    private func focus(_ s: Spot) {
        guard let rs = realmScene else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let target = rs.spot(s.uv.x, s.uv.y)
        rs.focus = nil
        rs.panTarget = simd_clamp(SIMD2(target.x - rs.homeCenterX, target.y) * 0.8, -rs.panLimit, rs.panLimit)
        rs.hero.look(at: [s.uv.x < 0.5 ? -0.7 : 0.7, s.uv.y > 0.36 ? 0.5 : -0.3])
        withAnimation(.sheet) { focused = s }
    }
    private func unfocus() {
        realmScene?.hero.look(at: nil)
        withAnimation(.sheet) { focused = nil }
    }
    private func spotCard(_ s: Spot) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: s.symbol).foregroundStyle(world.color)
                Text(s.title).font(.story(22))
                Spacer()
                Button { unfocus() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).frame(width: 30, height: 30).background(Circle().fill(.white.opacity(0.1)))
                }
            }
            Text(s.line).font(.ui(15)).foregroundStyle(.white.opacity(0.85)).frame(maxWidth: .infinity, alignment: .leading)
            if s.action != nil {
                Button { unfocus(); withAnimation(.sheet) { satchelOpen = true } } label: {
                    Text("Find a quest for it in your satchel").font(.ui(16)).frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(Capsule().fill(world.color.opacity(0.35))).overlay(Capsule().stroke(world.color, lineWidth: 1))
                }
            }
        }
        .foregroundStyle(.white).padding(18)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(red: 0.07, green: 0.06, blue: 0.08).opacity(0.92)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(world.color.opacity(0.5), lineWidth: 1))
        .padding(.bottom, 110)
        .transition(.move(edge: .bottom))
    }

    private func ppm(_ size: CGSize) -> CGFloat { size.height * CGFloat(scene.pointsPerMeterScale) }

    /// Drag to look around the Sanctuary, a little in any direction (Clash of Clans–style): past the limit the
    /// world resists like a rubber band, and letting go glides on (momentum), then settles back inside.
    private func lookAround(_ size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { v in
                if dragStartPan == nil { dragStartPan = scene.pan; scene.fingerDown = true }
                let raw = (dragStartPan ?? .zero) + SIMD2(-Float(v.translation.width), Float(v.translation.height)) / Float(ppm(size))
                scene.panTarget = SIMD2(EdgeSafety.rubberBand(raw.x, scene.panLimit.x), EdgeSafety.rubberBand(raw.y, scene.panLimit.y))
            }
            .onEnded { v in
                let projected = (dragStartPan ?? .zero) + SIMD2(-Float(v.predictedEndTranslation.width), Float(v.predictedEndTranslation.height)) / Float(ppm(size))
                scene.panTarget = simd_clamp(projected, -scene.panLimit, scene.panLimit)
                dragStartPan = nil; scene.fingerDown = false
            }
    }

    /// Past the limit, movement fades out smoothly (never more than ~5 cm beyond it): you feel the edge.
    private func rubber(_ x: Float, _ lim: Float) -> Float {
        let over = abs(x) - lim
        guard over > 0 else { return x }
        let k: Float = 0.05
        return (lim + k * (1 - exp(-over / k))) * (x < 0 ? -1 : 1)
    }

    private var topBar: some View {
        VStack(spacing: 4) {
            Text(world == .sanctuary ? "Sanctuary" : world.name).font(.story(world == .sanctuary ? 36 : 30, .medium)).foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 6)
            if let rs = realmScene {                                     // how awake this realm is
                Text("\(world.pillar) · \(Restoration.names[Restoration.level(depth: rs.heartDepth)]) · \(rs.litCount) \(RealmContent.lights(world)) lit")
                    .font(.ui(12, .semibold)).foregroundStyle(world.color)
                    .padding(.horizontal, 10).padding(.vertical, 3).background(Capsule().fill(.black.opacity(0.45)))
            }
            HUDBar(journey: model.journey, embers: shownEmbers ?? model.journey.embers)   // streak, day, Embers (134, 141, 146)
                .padding(.top, 4)
            // Your Flame's line of the day (from your last days).
            Text("“\(flameLine(model.journey))”")
                .font(.story(14).italic()).foregroundStyle(Theme.cream.opacity(0.9)).multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.9), radius: 5).shadow(color: .black.opacity(0.5), radius: 10)
                .padding(.horizontal, 30).padding(.top, 2)
        }
        .padding(.top, 8)
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { bandTop = $0; placeFlame() }
    }

    /// Decision 162: the Flame sits in the middle of the free space between the streak panel (with its line) and the
    /// quests, on every screen; its feet go about half a Flame below that middle.
    private func placeFlame() {
        let h = UIScreen.main.bounds.height
        guard bandTop > 0, bandBottom > bandTop, h > 0 else { return }
        let mid = (bandTop + bandBottom) / 2
        model.feetTarget = Float((mid + h * 0.03) / h)          // (calibrated on screen: the sprite's visible feet)
    }

    /// The tour's first stops: the satchel, then the world.
    @ViewBuilder private var tourLayer: some View {
        if model.tour == .grove && world == .grove && built {
            VStack {
                Spacer()
                TourBubble(text: "The Whispering Grove. Every kind word you send relights one of its lanterns. You can live here too: your satchel and your quests come with you to every world.",
                           button: "Home", next: {
                               model.tour = nil
                               withAnimation(.screen) { model.go(.home) }
                           }, skip: { withAnimation { model.tour = nil } })
                .padding(.horizontal, 16).padding(.bottom, 118)
            }
        } else if (model.tour == .satchel || model.tour == .world) && world == .sanctuary {
            VStack {
                Spacer()
                Group {
                    if model.tour == .satchel {
                        TourBubble(text: "This is your satchel. Each day I'll fill it with quests made for you. Take the ones you'll do: they'll wait for you right here.",
                                   button: "Next", next: { withAnimation(.sheet) { model.tour = .world } },
                                   skip: { withAnimation { model.tour = nil } })
                    } else {
                        TourBubble(text: "And this is the World. Out there, most of it sleeps in the Hush. Every light you send wakes a piece of it.",
                                   button: "Show me", next: {
                                       model.tour = .map
                                       withAnimation(.screen) { model.go(.map) }
                                   }, skip: { withAnimation { model.tour = nil } })
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 118)
            }
            .id(model.tour == .satchel ? 0 : 1)
        }
    }

    @ViewBuilder private var hint: some View {
        if model.tour != nil || focused != nil {
            EmptyView()
        } else if chosen.isEmpty && model.calls.contains(where: { !$0.done }) {
            Button { withAnimation(.sheet) { satchelOpen = true } } label: {
                HStack(spacing: 8) {
                    Text("Choose today's quests from your satchel").font(.story(15).italic())
                    Image(systemName: "chevron.up").font(.system(size: 10, weight: .semibold)).opacity(0.7)
                }
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(Capsule(style: .continuous).fill(.black.opacity(0.52)))
                .overlay(Capsule(style: .continuous).stroke(Theme.champagne.opacity(0.35), lineWidth: 0.5))
                .foregroundStyle(Theme.cream)
            }
            .padding(.bottom, 10)
        } else if focused == nil, let r = model.newHere.first(where: { $0 != world }) {
            Button { withAnimation(.screen) { model.go(.map) } } label: {
                HStack(spacing: 8) {
                    Text("Something new in \(r.name.replacingOccurrences(of: "The ", with: "the "))").font(.story(15).italic()).lineLimit(1).minimumScaleFactor(0.8)
                    Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)).opacity(0.7)
                }
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(Capsule(style: .continuous).fill(.black.opacity(0.52)))
                .overlay(Capsule(style: .continuous).stroke(Theme.champagne.opacity(0.35), lineWidth: 0.5))
                .foregroundStyle(Theme.cream)
            }
            .padding(.bottom, 10)
        }
    }

    private var cockpitBar: some View {
        HStack(spacing: 0) {
            barButton(.world, "World", badge: !model.newHere.isEmpty, image: UIImage(named: PixelMode.world ? "px-icon-world.png" : "icon-world.png")) { withAnimation(.screen) { model.go(.map) } }
            barButton(.satchel, "Satchel", badge: chosen.isEmpty && model.calls.contains(where: { !$0.done }), image: UIImage(named: PixelMode.world ? "px-icon-satchel.png" : "satchel.png")) {
                withAnimation(.sheet) { satchelOpen = true }
            }
            barButton(.book, "Book", badge: model.journey.newPages > 0, image: UIImage(named: PixelMode.world ? "px-icon-book.png" : "icon-book.png")) {
                withAnimation(.sheet) { bookOpen = true }
            }
            barButton(.flame, "Your Flame", badge: false, image: UIImage(named: PixelMode.world ? "px-icon-flame.png" : "icon-flame-v2.png") ?? SparkTint.image(PixelMode.sparkImage, ember: model.emberID)) {   // your Spark, free (no cage)
                if PerfProbe.on { print("TAP flame button") }
                director?.tapped()
                withAnimation(.sheet) { flameOpen = true }
            }
        }
        .padding(.vertical, 2)
    }

    /// One of the bar's four: a live painted icon (LiveIcon) that hops when tapped, its name below.
    private func barButton(_ kind: LiveIcon.Kind, _ label: String, badge: Bool, image: UIImage?, action: @escaping () -> Void) -> some View {
        Button {
            barTaps[label, default: 0] += 1
            action()
        } label: {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    LiveIcon(kind: kind, image: image, calling: badge, taps: barTaps[label, default: 0])
                    if badge { Circle().fill(Theme.ember).frame(width: 9, height: 9).offset(x: 4, y: -2) }
                }
                Text(label).font(.ui(12, .semibold)).opacity(0.9)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 4).foregroundStyle(Theme.cream)
            .contentShape(Rectangle())                        // the whole slot answers a tap, not only its word
        }
    }

    /// A quest you tapped in the world: the same parchment as the satchel's journal.
    private func card(_ call: Call, size: CGSize) -> some View {
        let ink = Color(red: 0.27, green: 0.17, blue: 0.1)
        return ZStack(alignment: .bottom) {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { withAnimation(.sheet) { open = nil } }
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Button { withAnimation(.sheet) { open = nil } } label: {
                        Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(ink.opacity(0.6))
                            .frame(width: 30, height: 30).background(Circle().fill(ink.opacity(0.08)))
                    }
                }
                Image(systemName: call.symbol).font(.system(size: 24, weight: .semibold)).foregroundStyle(call.realm.color)
                    .frame(width: 54, height: 54).background(Circle().fill(Color(red: 0.2, green: 0.13, blue: 0.08)))
                    .shadow(color: call.realm.color.opacity(0.5), radius: 10)
                Text(call.title).font(.story(26)).foregroundStyle(ink)
                Text(call.detail).font(.ui(15)).multilineTextAlignment(.center).foregroundStyle(ink.opacity(0.8))
                if !call.reason.isEmpty {
                    Text(call.reason).font(.story(14).italic()).multilineTextAlignment(.center).foregroundStyle(ink.opacity(0.65))
                }
                // The heart of it: every day, not how hard.
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").font(.system(size: 11)).foregroundStyle(Theme.accent)
                    Text(Consistency.line(call.title.count)).font(.story(14, .medium)).foregroundStyle(Theme.accent)
                }
                .multilineTextAlignment(.center)
                QuestMeta(call: call, streak: model.journey.questStreak(call.title), ink: ink)
                let live = model.calls.first { $0.id == call.id } ?? call
                if live.counted {
                    // Progress inside the quest (reps, pages, minutes): tap to count, it fills as you go.
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(live.progress) / \(live.target) \(live.unit)").font(.num(22, .bold)).monospacedDigit()
                                .contentTransition(.numericText(value: Double(live.progress))).foregroundStyle(ink)
                            Spacer()
                            Button { withAnimation(.spring(response: 0.3)) { model.step(call.id, by: max(1, live.target / 10)) } } label: {
                                Text(live.target >= 10 ? "+\(max(1, live.target / 10))" : "+1").font(.num(17, .bold))
                                    .frame(width: 64, height: 40).background(Capsule().fill(call.realm.color.opacity(0.3)))
                                    .overlay(Capsule().stroke(call.realm.color, lineWidth: 1.2)).foregroundStyle(ink)
                            }
                        }
                        GeometryReader { g in
                            Capsule().fill(ink.opacity(0.1))
                            Capsule().fill(call.realm.color).frame(width: g.size.width * CGFloat(live.progress) / CGFloat(max(1, live.target)))
                        }
                        .frame(height: 8).animation(.spring(response: 0.35), value: live.progress)
                    }
                    .padding(.top, 4)
                }
                Button { finish(call, size: size) } label: {
                    GoldButtonLabel(text: live.counted && live.progress < live.target ? "Done, all of it" : "I did it")
                }
                .padding(.top, 4)
                Button { withAnimation(.sheet) { model.skip(call.id); open = nil } } label: {
                    Text("Not today").font(.ui(14)).foregroundStyle(ink.opacity(0.6))
                }
            }
            .padding(20)
            .background(
                SheetPaper()
            )
            .padding(.horizontal, 14).padding(.bottom, 24)
            .transition(.move(edge: .bottom))
        }
    }

    private func finish(_ call: Call, size: CGSize, from given: CGPoint? = nil) {
        let from = given ?? scene.screenPoint(world: spotFor(call), in: fullSize)
        withAnimation { open = nil }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let outcome = withAnimation(.sheet) { model.complete(call.id) }
        strand = (from, Date())
        if let e = outcome?.embers, e > 0 { coins(from: from, amount: e) }      // the Embers burst out and fly up
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            strand = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if let outcome { withAnimation(.spring(response: 0.4)) { reward = outcome } }   // +XP, the number climbs, milestones
            if let f = outcome?.evolvedTo { model.showForm(f) }                              // a new form, everywhere (decision 152)
            if call.realm == world { realmScene?.act() }        // done here, for this realm: its next lights relight
            director?.actionCompleted(call.realm == .grove ? .heart : call.realm == .library ? .mind : call.realm == .highlands ? .body : .spirit)
        }
    }

    /// Coins burst from a point and fly into the counter, which counts up as each one lands.
    private func coins(from: CGPoint, amount: Int) {
        let n = min(10, max(3, amount / 2))
        burstAmount = amount
        shownEmbers = model.journey.embers - amount
        burst = .init(from: from, to: coinTarget, coins: n, start: Date())
    }

    private func flash(_ s: String) {
        withAnimation { toast = s }
        Task { @MainActor in try? await Task.sleep(for: .seconds(2.4)); withAnimation { toast = nil } }
    }
}

/// A call as a glowing scroll tag (UI kit style anchor).
struct CallTag: View {
    let call: Call
    @State private var bob = false
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: call.symbol).font(.system(size: 13)).foregroundStyle(call.realm.color)
            Text(call.title).font(.ui(14)).foregroundStyle(.white)
        }
        .padding(.horizontal, 13).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.07, green: 0.09, blue: 0.06).opacity(0.82)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(call.realm.color.opacity(0.8), lineWidth: 1.2))
        .shadow(color: call.realm.color.opacity(0.55), radius: 8)
        .offset(y: bob ? -3 : 3)
        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: bob)
        .onAppear { bob = true }
    }
}

/// A quest waiting in the world: its painted object (a lantern, a scroll, a crystal, a bud) glowing softly in its
/// realm's color, breathing and bobbing, with its name beneath.
struct QuestObject: View {
    let call: Call
    @State private var bob = false
    var body: some View {
        let _ = PerfProbe.body("QuestObject")
        VStack(spacing: 2) {
            ZStack {
                Ellipse().fill(RadialGradient(colors: [call.realm.color.opacity(0.45), call.realm.color.opacity(0)], center: .center, startRadius: 2, endRadius: 40))
                    .frame(width: 84, height: 70).scaleEffect(bob ? 1.1 : 0.92).opacity(bob ? 1 : 0.7)
                Image(uiImage: UIImage(named: "\(call.prop).png") ?? UIImage()).resizable().scaledToFit()
                    .frame(width: 50, height: 52)
                    .shadow(color: call.realm.color.opacity(0.6), radius: 7)
            }
            // Its name, quietly: italic, on a soft shade (no box).
            Text(call.title).font(.story(13).italic()).foregroundStyle(Theme.cream)
                .shadow(color: .black.opacity(0.85), radius: 4).shadow(color: .black.opacity(0.5), radius: 10)
        }
        .offset(y: bob ? -3 : 2)
        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: bob)
        .onAppear { bob = true }
        .contentShape(Rectangle())
    }
}

/// The Quest Satchel (iteration 2, decision 124): a parchment journal with today's offered quests. Take up to three;
/// each one then waits for you in the Sanctuary.
struct QuestJournal: View {
    let model: ShellModel
    @Binding var isOpen: Bool
    @State private var tab = 0                      // To do · Done · Skipped (Life Reset-style, decision 134)
    @Namespace private var tabLine
    private let ink = Color(red: 0.27, green: 0.17, blue: 0.1)
    private var todo: [Call] { model.calls.filter { !$0.done && !$0.skipped } }
    private var done: [Call] { model.calls.filter { $0.done } }
    private var skipped: [Call] { model.calls.filter { $0.skipped && !$0.done } }
    /// The Companion's suggestion: the first untaken quest with a reason.
    private var suggested: Call? { todo.first { !$0.chosen && !$0.reason.isEmpty } }

    var body: some View {
        let _ = PerfProbe.body("Satchel")
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35).ignoresSafeArea().onTapGesture { close() }
            VStack(spacing: 0) {
                Capsule().fill(ink.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 10)
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Day \(model.journey.roundDay)").font(.story(30, .bold)).foregroundStyle(ink)
                        + Text(" / \(model.journey.roundLength)").font(.story(18)).foregroundStyle(ink.opacity(0.5))
                        Text("Choose what you'll do today. Each one waits for you in the world.")
                            .font(.ui(13)).foregroundStyle(ink.opacity(0.7))
                    }
                    Spacer()
                    Text("\(model.chosenCount) of \(ShellModel.maxChosen)").font(.ui(13, .bold)).foregroundStyle(ink.opacity(0.7))
                }
                .padding(.horizontal, 22).padding(.top, 8)
                tabs.padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 8)
                ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        Color.clear.frame(height: 0).id("top")
                        if tab == 0, let s = suggested { suggestion(s) }
                        ForEach(tab == 0 ? todo.filter { $0.id != suggested?.id } : tab == 1 ? done : skipped) { call in QuestCardRow(model: model, call: call, ink: ink) }
                        if (tab == 1 && done.isEmpty) || (tab == 2 && skipped.isEmpty) {
                            Text(tab == 1 ? "Nothing done yet today. The first one lights your flame." : "Nothing skipped. Skipping is allowed: it never costs you anything.")
                                .font(.ui(14)).foregroundStyle(ink.opacity(0.6)).multilineTextAlignment(.center).padding(.vertical, 30)
                        }
                        Color.clear.frame(height: 0).id("bottom")
                    }
                    .padding(.horizontal, 16).padding(.bottom, 12)
                }
                .onReceive(NotificationCenter.default.publisher(for: .perfScroll)) { n in
                    withAnimation(.easeInOut(duration: 1.2)) { proxy.scrollTo(n.object as? String ?? "top") }
                }
                }
                .frame(maxHeight: 470)
                Button { close() } label: {
                    GoldButtonLabel(text: model.chosenCount == 0 ? "Close" : "Into the world")
                }
                .padding(.horizontal, 18).padding(.bottom, 18)
            }
            .background(
                SheetPaper()
            )
            .padding(.horizontal, 10).padding(.bottom, 8)
        }
    }

    private var tabs: some View {
        HStack(spacing: 8) {
            ForEach(Array(["To do \(todo.count)", "Done \(done.count)", "Skipped \(skipped.count)"].enumerated()), id: \.offset) { i, t in
                Button { withAnimation(Motion.soft) { tab = i } } label: {
                    // Words, and one slim gold line sliding under the one you're on (decision 146).
                    VStack(spacing: 5) {
                        Text(t).font(.story(15, tab == i ? .medium : .regular)).foregroundStyle(ink.opacity(tab == i ? 1 : 0.45))
                        ZStack {
                            if tab == i { Capsule().fill(Theme.champagneDeep).frame(height: 1.5).matchedGeometryEffect(id: "tab", in: tabLine) }
                            else { Color.clear.frame(height: 1.5) }
                        }
                    }
                    .fixedSize()
                    .padding(.horizontal, 6)
                }
            }
            Spacer()
        }
    }

    private func suggestion(_ c: Call) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Suggested for you", systemImage: "sparkles").font(.ui(12, .bold)).foregroundStyle(ink.opacity(0.7))
            QuestCardRow(model: model, call: c, ink: ink)
            Text(c.reason).font(.ui(13)).foregroundStyle(ink.opacity(0.75)).padding(.horizontal, 4)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(red: 1, green: 0.85, blue: 0.55).opacity(0.25)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(red: 0.85, green: 0.6, blue: 0.25).opacity(0.6), lineWidth: 1))
    }

    private func close() {
        let taken = model.calls.filter { $0.chosen }.map(\.title)
        if !taken.isEmpty { model.journey.firstQuests(taken) }          // the Book's page about your first quests
        withAnimation(.sheet) { isOpen = false }
    }
}

/// "9d · Daily · Medium · 0 / 20 reps": a quest's detail line (its own streak, how often, how hard, how far).
struct QuestMeta: View {
    let call: Call, streak: Int, ink: Color
    var body: some View {
        HStack(spacing: 8) {
            if streak > 0 {
                Label("\(streak)d", systemImage: "flame.fill").foregroundStyle(Color(red: 0.85, green: 0.4, blue: 0.1))
            }
            Label(call.frequency, systemImage: "arrow.triangle.2.circlepath")
            Label(call.difficulty, systemImage: call.difficulty == "Hard" ? "cellularbars" : call.difficulty == "Medium" ? "chart.bar.fill" : "chart.bar")
            Text(call.counted ? "\(call.progress) / \(call.target) \(call.unit)" : "\(call.minutes) min")
        }
        .font(.ui(11, .bold)).foregroundStyle(ink.opacity(0.65)).labelStyle(.titleAndIcon)
    }
}

/// A big illustrated quest card: its realm's painting behind it, its title, its meta line, and Take / Skip.
struct QuestCardRow: View {
    let model: ShellModel
    let call: Call
    let ink: Color
    private static var thumbs: [String: UIImage] = [:]
    private static func thumb(_ r: RealmID) -> UIImage? {
        // Pre-made small thumbnails (tools: thumb-<world>.jpg): no shrinking big paintings when the satchel opens.
        if let t = UIImage(named: "thumb-\(r.rawValue).jpg") { return t }
        let name = r == .sanctuary ? "home-paint.png" : (UIImage(named: "\(r.rawValue)-world-paint.png") != nil ? "\(r.rawValue)-world-paint.png" : "home-paint.png")
        if let t = thumbs[name] { return t }
        return PerfProbe.measure("quest thumb \(name)") {
            guard let src = UIImage(named: name) else { return nil }
            let w: CGFloat = 520, h = w * src.size.height / src.size.width
            let t = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { _ in src.draw(in: CGRect(x: 0, y: 0, width: w, height: h)) }
            thumbs[name] = t; return t
        }
    }
    var body: some View {
        let _ = PerfProbe.body("QuestCard")
        let full = model.chosenCount >= ShellModel.maxChosen && !call.chosen
        ZStack(alignment: .bottomLeading) {
            if let t = Self.thumb(call.realm) {
                Image(uiImage: t).resizable().scaledToFill().frame(height: 112).frame(maxWidth: .infinity).clipped()
            }
            LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
            HStack(alignment: .bottom, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(call.title).font(.story(21, .semibold)).foregroundStyle(.white)
                    QuestMeta(call: call, streak: model.journey.questStreak(call.title), ink: .white)
                }
                Spacer()
                if call.done {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 26)).foregroundStyle(Color(red: 1, green: 0.85, blue: 0.4))
                } else if call.skipped {
                    Button { withAnimation(.snappy) { model.unskip(call.id) } } label: { pill("Bring back", on: false) }
                } else {
                    VStack(spacing: 6) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(duration: 0.35)) { model.toggleChosen(call.id) }
                        } label: { pill(call.chosen ? "Taken" : "Take", on: call.chosen) }
                        .disabled(full).opacity(full ? 0.45 : 1)
                        if !call.chosen {
                            Button { withAnimation(.snappy) { model.skip(call.id) } } label: {
                                Text("Skip").font(.ui(12)).foregroundStyle(.white.opacity(0.75))
                            }
                        }
                    }
                }
            }
            .padding(12)
            Image(uiImage: UIImage(named: "\(call.prop).png") ?? UIImage()).resizable().scaledToFit().frame(width: 30, height: 34)
                .padding(10).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .frame(height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(call.chosen ? call.realm.color : .white.opacity(0.2), lineWidth: call.chosen ? 2 : 1))
        .opacity(call.done ? 0.75 : 1)
    }
    private func pill(_ t: String, on: Bool) -> some View {
        Text(t).font(.ui(14, .bold))
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(Capsule().fill(on ? Color(red: 1, green: 0.78, blue: 0.42) : .black.opacity(0.35)))
            .overlay(Capsule().stroke(Color(red: 1, green: 0.78, blue: 0.42), lineWidth: 1.2))
            .foregroundStyle(on ? Color(red: 0.25, green: 0.12, blue: 0.05) : .white)
    }
}
