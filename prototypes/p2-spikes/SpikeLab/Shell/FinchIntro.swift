// The introduction, Finch-style (decision 114, docs/plan-2.0/intro-finch-spec.md): one thing per screen on a soft
// dusk gradient, your Flame centered and reacting; choose your ember → hold to warm it → it cracks → light rays →
// the Spark is born → it asks your name → "what am I?" (+1 light) → foreshadowing (stages, the world) → mornings →
// three quick questions → preparing → your first-light list → the world reveal.
import SwiftUI
import RealityKit

enum IntroStep: Int, CaseIterable { case welcome, chooseEmber, warm, born, hello, whatAmI, growing, world, mornings, q1, q2, q3, preparing, firstLight }

struct EmberChoice: Identifiable, Hashable {
    let id: String, word: String, pillar: String, color: Color, realm: RealmID, interest: String
}
let emberChoices: [EmberChoice] = [
    .init(id: "heart", word: "Love", pillar: "Heart", color: Color(red: 1.0, green: 0.55, blue: 0.62), realm: .grove, interest: "Be closer to people I love"),
    .init(id: "mind", word: "Curiosity", pillar: "Mind", color: Color(red: 0.5, green: 0.72, blue: 1.0), realm: .library, interest: "Read again"),
    .init(id: "body", word: "Strength", pillar: "Body", color: Color(red: 1.0, green: 0.55, blue: 0.22), realm: .highlands, interest: "Move a little every day"),
    .init(id: "spirit", word: "Calm", pillar: "Spirit", color: Color(red: 0.8, green: 0.85, blue: 1.0), realm: .stillwater, interest: "Find calm"),
    .init(id: "craft", word: "Craft", pillar: "Craft", color: Color(red: 0.88, green: 0.66, blue: 0.4), realm: .forge, interest: "Make something / focus"),
    .init(id: "world", word: "Wonder", pillar: "World", color: Color(red: 0.6, green: 0.88, blue: 0.5), realm: .wilds, interest: "Spend time in nature"),
]

private let gold = Color(red: 1.0, green: 0.78, blue: 0.42)
private let cream = Color(red: 1.0, green: 0.95, blue: 0.86)

/// The intro's Flame: the living layered Flame alone, centered, with a hatch spring.
@MainActor final class IntroFlameStage {
    let root = Entity(), camera = PerspectiveCamera(), flame = HeroRig(base: "d", footInset: 22.0 / 426.0, reflection: false, glows: true, wander: 0.01)
    var appear = Spring(0, stiffness: 90, damping: 9), target: Float = 0
    var updates: EventSubscription?
    func build() async throws {
        try await flame.build()
        root.addChild(flame.leanPivot)
        flame.leanPivot.position = [0, -0.04, 0]
        camera.camera.fieldOfViewInDegrees = 40
        camera.look(at: [0, 0.02, 0], from: [0, 0.03, 0.6], relativeTo: nil)
        root.addChild(camera)
    }
    func update(_ dt: Float) {
        appear.step(toward: target, dt: dt)
        flame.leanPivot.scale = .init(repeating: max(0, appear.value))
        flame.update(dt: dt)
    }
}

struct FinchIntro: View {
    let model: ShellModel
    @State private var step: IntroStep = .welcome
    @State private var ember: EmberChoice?
    @State private var name = ""
    @State private var warmth: CGFloat = 0           // coarse (for the words and the hatch); the ember itself uses warmAt
    /// Warming follows time, frame by frame (no steps): it rises while you hold and cools gently when you let go.
    @State private var warmFrom: CGFloat = 0
    @State private var warmSince: Date = .distantPast
    private static let warmRate: CGFloat = 1 / 2.2, coolRate: CGFloat = 0.35
    private func warmAt(_ d: Date) -> CGFloat {
        let e = CGFloat(d.timeIntervalSince(warmSince))
        return holding ? min(1, warmFrom + e * Self.warmRate) : max(max(0, warmFrom - 0.25), warmFrom - e * Self.coolRate)
    }
    @State private var holding = false
    @State private var rays = false
    @State private var lightToast = false
    @State private var answers: [Int: Set<String>] = [:]
    @State private var ring: CGFloat = 0
    private var scene: SanctuaryScene { model.sanctuary }
    @State private var worldVitality: Float = 0.12
    @State private var meter = FrameMeter()
    @State private var director: AliveDirector?
    private var flameReady: Bool { model.sanctuaryBuilt }
    @State private var bubble: String?
    @FocusState private var typing: Bool
    @State private var full: CGSize = .zero
    /// The ember dissolving into light as the Spark is born (0 = whole, 1 = gone).
    @State private var emberGone: CGFloat = 0
    /// The glimpse of what the Spark will become: the stage shown (nil = the living Spark itself) and a flash.
    @State private var morph: Int?
    @State private var morphFlash: Double = 0
    @State private var glimpseDone = false
    private static let stages = ["stage-spark", "stage-flame", "stage-blaze", "stage-kindled", "stage-beyond"]
    private static let stageHeights: [CGFloat] = [282, 464, 602, 681, 716]

    private var flameVisible: Bool { step.rawValue >= IntroStep.born.rawValue }

    var body: some View {
        ZStack {
            // The intro happens in the Sanctuary itself (drawn by the app's one 3D view underneath, the same world
            // home keeps afterwards): grey and silent (the Hush) until your Flame is born.
            DuskBackground().opacity(flameReady ? 0 : 1).animation(.easeOut(duration: 1.2), value: flameReady).allowsHitTesting(false)
            // Everything that belongs to the Flame's spot follows it on screen: the ember you warm sits on the stone
            // circle, the Spark is born from it in the same place, and the glimpse of its future appears there too.
            GeometryReader { g in
                TimelineView(.animation) { tl in
                    let f = scene.flameScreen(in: g.size)
                    ZStack {
                        if step == .warm || (step == .born && emberGone < 1) {
                            let w = warmAt(tl.date)
                            EmberOrb(color: ember?.color ?? gold, size: max(60, f.height * 0.55), warmth: w, cracks: w)
                                .scaleEffect((holding ? 1.06 + w * 0.08 : 1) * (1 + emberGone * 0.6))
                                .opacity(1 - emberGone)
                                .offset(x: holding ? sin(tl.date.timeIntervalSinceReferenceDate * 47) * w * 2.5 : 0)   // a smooth tremble
                                .position(x: f.feet.x, y: f.feet.y - max(60, f.height * 0.55) * 0.5)
                                .gesture(DragGesture(minimumDistance: 0).onChanged { _ in if !holding { startWarming() } }.onEnded { _ in stopWarming() })
                        }
                        if let m = morph {
                            let h = f.height * Self.stageHeights[m] / Self.stageHeights[0] * 0.95
                            Image(uiImage: SparkTint.image("\(Self.stages[m]).png", ember: model.emberID) ?? UIImage()).resizable().scaledToFit()
                                .frame(height: h)
                                .position(x: f.feet.x, y: f.feet.y - h * 0.5 + f.height * 0.08)
                                .id(m).transition(.scale(scale: 0.8).combined(with: .opacity))
                                .allowsHitTesting(false)
                        }
                        Circle().fill(RadialGradient(colors: [.white.opacity(morphFlash), Color(red: 1, green: 0.8, blue: 0.45).opacity(morphFlash * 0.6), .clear], center: .center, startRadius: 0, endRadius: f.height * 1.6))
                            .frame(width: f.height * 3.2, height: f.height * 3.2)
                            .position(x: f.feet.x, y: f.feet.y - f.height * 0.5).allowsHitTesting(false)
                    }
                    .frame(width: g.size.width, height: g.size.height)
                }
                .onAppear { full = g.size }
            }
            .ignoresSafeArea()
            BirthBloom(on: rays, center: full == .zero ? nil : scene.flameScreen(in: full).feet).allowsHitTesting(false)
            // Soft shade behind the words so they read on the painting (top for the Flame's speech, bottom for choices).
            LinearGradient(colors: [.black.opacity(0.45), .clear, .clear, .black.opacity(0.62)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea().allowsHitTesting(false)
            VStack(spacing: 0) {
                if step.rawValue >= IntroStep.q1.rawValue && step.rawValue <= IntroStep.q3.rawValue { progressBar.padding(.top, 8) }
                Spacer(minLength: 0)
                content
                    .id(step)
                    // The old words leave quickly, then the new ones arrive: never two texts on top of each other.
                    .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 12)).animation(.smooth(duration: 0.34).delay(0.14)),
                                            removal: .opacity.animation(.easeOut(duration: 0.12))))
            }
            .padding(.horizontal, 26).padding(.bottom, 28)
            if let bubble { speech(bubble) }
            if lightToast { toast }
        }
        .animation(.smooth(duration: 0.38), value: step)
        .onAppear {
            meter.start()
            scene.hideFlameInstantly()                      // not born yet
            scene.setVitality(worldVitality)
            setUpWorld()
            if CommandLine.arguments.contains("-autointro") { autoplay() }
        }
        .onChange(of: model.sanctuaryBuilt) { _, _ in scene.setVitality(worldVitality); setUpWorld() }
        .onDisappear { meter.stop(); director?.stop() }     // home's own director takes over the same Spark
    }

    // MARK: Screens

    @ViewBuilder private var content: some View {
        switch step {
        case .welcome:
            VStack(spacing: 18) {
                Spacer()
                EmberOrb(color: gold, size: 90, warmth: 0.2, cracks: 0)
                Spacer()
                title("Every person carries a flame.")
                body2("Most never see it. Yours is waiting.")
                Spacer().frame(height: 30)
                primary("Light your ember") { go(.chooseEmber) }
                Text("Private test · for adults 18+").font(.caption2).foregroundStyle(cream.opacity(0.4)).padding(.top, 6)
            }
        case .chooseEmber:
            VStack(spacing: 14) {
                title("Which light are you drawn to?")
                body2("Your ember carries it. You can grow every light later.")
                emberRing.frame(height: 380)
                primary("Warm this ember", disabled: ember == nil) { go(.warm) }
            }
        case .warm:
            VStack(spacing: 16) {
                title(warmth > 0.66 ? "Almost…" : "Hold it close. Keep it warm.")
                body2("Touch and hold the ember on the stone circle.")
                Spacer().frame(height: 20)
            }
        case .born:
            VStack(spacing: 14) {
                title("Your Flame is born.")
                body2("Small, curious, and entirely yours.")
                primary("Say hello") { go(.hello) }
            }
        case .hello:
            VStack(spacing: 14) {
                TextField("", text: $name, prompt: Text("Your name").foregroundColor(cream.opacity(0.45)))
                    .font(.story(22)).multilineTextAlignment(.center).foregroundStyle(cream)
                    .padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.10)))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(gold.opacity(0.4), lineWidth: 1))
                    .focused($typing).submitLabel(.done).onSubmit { if !name.isEmpty { go(.whatAmI) } }
                primary("Next", disabled: name.trimmingCharacters(in: .whitespaces).isEmpty) { go(.whatAmI) }
            }
        case .whatAmI:
            VStack(spacing: 12) {
                choice("The part of me that's alive") { gotLight() }
                choice("A little fire that grows when I do") { gotLight() }
            }
        case .growing:
            VStack(spacing: 16) {
                if glimpseDone {
                    body2("It takes real days. That's the point.")
                    primary("Next") { go(.world) }
                } else {
                    Spacer().frame(height: 60)
                }
            }
        case .world:
            VStack(spacing: 16) {
                worldWindow.frame(width: 250, height: 250)
                body2("Every real thing you do wakes a piece of it.")
                primary("Next") { go(.mornings) }
            }
        case .mornings:
            VStack(spacing: 12) {
                primary("Turn on mornings") { go(.q1) }
                secondary("Maybe later") { go(.q1) }
            }
        case .q1:
            question("What would make this year feel alive?", sub: "Pick as many as you like", options: emberChoices.map(\.interest), multi: true, key: 1, next: .q2)
        case .q2:
            question("On a normal day, how much time is truly yours?", sub: nil, options: ["About 5 minutes", "About 15 minutes", "Half an hour", "More than that"], multi: false, key: 2, next: .q3)
        case .q3:
            question("Where are you starting from?", sub: nil, options: ["Just starting out", "I have a few good habits", "I'm already quite active"], multi: false, key: 3, next: .preparing)
        case .preparing:
            VStack(spacing: 14) {
                ZStack {
                    Circle().stroke(.white.opacity(0.12), lineWidth: 6)
                    Circle().trim(from: 0, to: ring).stroke(gold, style: .init(lineWidth: 6, lineCap: .round)).rotationEffect(.degrees(-90))
                }
                .frame(width: 120, height: 120)
                title("Preparing your first days…")
                Spacer().frame(height: 40)
            }
            .task {
                withAnimation(.easeInOut(duration: 2.2)) { ring = 1 }           // one smooth fill (no steps)
                // The natural loading moment: the map and the Grove get ready now, never later while you play.
                async let ready: Void = model.preloadCore()
                try? await Task.sleep(for: .milliseconds(2200))
                await ready
                scene.hero.react(.cheer); FeelSound.shared.chime(4)
                try? await Task.sleep(for: .milliseconds(500)); go(.firstLight)
            }
        case .firstLight:
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your first light").font(.story(22)).foregroundStyle(Color(red: 0.35, green: 0.2, blue: 0.1))
                    ForEach(firstThings, id: \.self) { t in
                        HStack(spacing: 10) {
                            Circle().fill(gold).frame(width: 9, height: 9).shadow(color: .orange, radius: 4)
                            Text(t).font(.ui(16)).foregroundStyle(Color(red: 0.3, green: 0.2, blue: 0.12))
                        }
                    }
                }
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color(red: 0.98, green: 0.93, blue: 0.82)))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                body2("In a few days, I'll want a name.")
                primary("Let's begin") { finish() }
            }
        }
    }

    // MARK: Pieces

    private func title(_ s: String) -> some View {
        Text(s).font(.custom("Georgia", size: 27)).fontWeight(.regular).multilineTextAlignment(.center).foregroundStyle(cream)
            .shadow(color: .black.opacity(0.2), radius: 4)
    }
    private func body2(_ s: String) -> some View {
        Text(s).font(.ui(16)).multilineTextAlignment(.center).foregroundStyle(cream.opacity(0.78))
    }
    private func primary(_ s: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button { FeelHaptics.shared.nudge(); action() } label: {
            Text(s).font(.story(18, .semibold)).frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Capsule().fill(LinearGradient(colors: [Color(red: 1, green: 0.8, blue: 0.45), Color(red: 0.95, green: 0.58, blue: 0.28)], startPoint: .top, endPoint: .bottom)))
                .foregroundStyle(Color(red: 0.32, green: 0.16, blue: 0.06))
                .shadow(color: Color(red: 1, green: 0.55, blue: 0.2).opacity(disabled ? 0 : 0.5), radius: 12, y: 4)
        }
        .disabled(disabled).opacity(disabled ? 0.45 : 1)
    }
    private func secondary(_ s: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(s).font(.ui(16)).foregroundStyle(cream.opacity(0.75)).padding(10) }
    }
    private func choice(_ s: String, selected: Bool = false, action: @escaping () -> Void) -> some View {
        Button { FeelHaptics.shared.nudge(); action() } label: {
            HStack {
                Text(s).font(.ui(17)).multilineTextAlignment(.leading)
                Spacer()
                if selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(gold) }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 16).fill(selected ? Color(red: 0.42, green: 0.24, blue: 0.10) : Color(red: 0.20, green: 0.13, blue: 0.11)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? gold : gold.opacity(0.22), lineWidth: selected ? 2 : 1))
            .foregroundStyle(cream)
        }
    }

    private func question(_ q: String, sub: String?, options: [String], multi: Bool, key: Int, next: IntroStep) -> some View {
        questionBody(q, sub: sub, options: options, multi: multi, key: key, next: next)
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 26).fill(Color(red: 0.11, green: 0.07, blue: 0.07).opacity(0.92)))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(gold.opacity(0.35), lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
    }

    private func questionBody(_ q: String, sub: String?, options: [String], multi: Bool, key: Int, next: IntroStep) -> some View {
        VStack(spacing: 10) {
            Text(q).font(.custom("Georgia", size: 22)).multilineTextAlignment(.center).foregroundStyle(cream)
            if let sub { body2(sub) }
            Spacer().frame(height: 6)
            let columns = multi ? [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)] : [GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 10) {
            ForEach(options, id: \.self) { o in
                choice(multi ? shortLabel(o) : o, selected: answers[key, default: []].contains(o)) {
                    var set = answers[key, default: []]
                    if multi { if set.contains(o) { set.remove(o) } else { set.insert(o) } } else { set = [o] }
                    answers[key] = set
                    scene.hero.react(.giggle)
                    if !multi { Task { try? await Task.sleep(for: .milliseconds(350)); go(next) } }
                }
            }
            }
            if multi { primary("Next", disabled: answers[key, default: []].isEmpty) { go(next) }.padding(.top, 6) }
        }
    }

    private func shortLabel(_ o: String) -> String {
        ["Be closer to people I love": "People I love", "Read again": "Reading", "Find calm": "Calm",
         "Move a little every day": "Moving", "Make something / focus": "Making & focus", "Spend time in nature": "Nature"][o] ?? o
    }

    private var progressBar: some View {
        let k = CGFloat(step.rawValue - IntroStep.q1.rawValue + 1) / 3
        return Capsule().fill(.white.opacity(0.15)).frame(height: 6)
            .overlay(alignment: .leading) { GeometryReader { g in Capsule().fill(gold).frame(width: g.size.width * k) } }
            .animation(.spring(duration: 0.5), value: k)
            .padding(.horizontal, 30)
    }

    private var emberRing: some View {
        GeometryReader { g in
            let c = CGPoint(x: g.size.width / 2, y: g.size.height / 2), r = min(g.size.width, g.size.height) * 0.38
            ZStack {
                EmberOrb(color: ember?.color ?? gold.opacity(0.6), size: 110, warmth: ember == nil ? 0.1 : 0.45, cracks: 0)
                    .position(c).animation(.spring(duration: 0.5), value: ember)
                ForEach(Array(emberChoices.enumerated()), id: \.element.id) { i, e in
                    let a = Double(i) / 6 * 2 * .pi - .pi / 2
                    Button {
                        withAnimation(.spring(duration: 0.4)) { ember = e }
                        FeelHaptics.shared.nudge(); FeelSound.shared.chime(i)
                    } label: {
                        VStack(spacing: 6) {
                            EmberOrb(color: e.color, size: ember == e ? 54 : 44, warmth: ember == e ? 0.6 : 0.25, cracks: 0)
                            Text(e.word).font(.ui(13, .bold)).foregroundStyle(ember == e ? e.color : cream.opacity(0.7))
                        }
                    }
                    .position(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
                }
            }
        }
    }

    private var stageStrip: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                VStack(spacing: 4) {
                    Image(uiImage: UIImage(named: "stage\(i).png") ?? UIImage()).resizable().scaledToFit()
                        .frame(width: i == 0 ? 66 : 56, height: i == 0 ? 66 : 56)
                        .overlay { if i == 4 { Text("?").font(.story(22, .bold)).foregroundStyle(cream.opacity(0.8)) } }
                    Text(["Spark", "Flame", "Blaze", "Kindled", "…"][i]).font(.ui(11)).foregroundStyle(cream.opacity(i == 0 ? 1 : 0.5))
                }
                if i < 4 { Image(systemName: "chevron.right").font(.system(size: 9)).foregroundStyle(cream.opacity(0.35)) }
            }
        }
        .padding(.vertical, 10).padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.07)))
    }

    private var worldWindow: some View {
        ZStack {
            Image(uiImage: UIImage(named: "world-window.png") ?? UIImage()).resizable().scaledToFit()
            Image(uiImage: UIImage(named: "world-window-color.png") ?? UIImage()).resizable().scaledToFit()
                .mask(RadialGradient(colors: [.white, .clear], center: ember.map(realmSpot) ?? .center, startRadius: 4, endRadius: 70))
            Circle().stroke(gold.opacity(0.5), lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.35), radius: 14)
    }
    /// Where each realm sits inside the world window (the window shows map rows 560–1363).
    private func realmSpot(_ e: EmberChoice) -> UnitPoint {
        let p = e.realm.mapPoint
        return UnitPoint(x: min(0.92, max(0.08, p.x / 803)), y: min(0.92, max(0.08, (p.y - 560) / 803)))
    }

    private func speech(_ s: String) -> some View {
        VStack {
            EmberText(text: s)
                .padding(.horizontal, 18).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.12, green: 0.08, blue: 0.10).opacity(0.78)))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(gold.opacity(0.45), lineWidth: 1))
                .padding(.horizontal, 30)
                .id(s)
                .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.1)),
                                        removal: .opacity.animation(.easeOut(duration: 0.1))))
            Spacer()
        }
        .padding(.top, 34)
        .allowsHitTesting(false)
    }

    private var toast: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "sparkle").foregroundStyle(gold)
                Text("+1 light · your Flame's first light").font(.ui(15, .bold))
            }
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(Capsule().fill(Color(red: 0.3, green: 0.18, blue: 0.1).opacity(0.9))).foregroundStyle(cream)
            .padding(.bottom, 200)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: Flow

    private func go(_ s: IntroStep) {
        typing = false
        withAnimation(.smooth(duration: 0.38)) { step = s }
        switch s {
        case .warm: scene.focus = scene.flameFocus          // the camera leans in to the circle, where the ember waits
        case .born: bubble = nil
        case .hello: say("…Oh! There you are. I'm your Flame. What's your name?")
        case .whatAmI: say("Nice to meet you, \(name.trimmingCharacters(in: .whitespaces)). Do you know what I am?")
        case .growing: say("I'm tiny now. But one day…"); glimpse()
        case .world: say("Out there, the world went quiet."); scene.hero.look(at: [0.5, -0.5])
        case .mornings: say("Can I bring you your day each morning?"); scene.hero.look(at: nil)
        case .q1: say("Let's learn a little about you.")
            scene.focus = scene.flameFocus - SIMD3(0, 0.085, 0)   // aim lower: the Flame watches from above the questions
        case .q2, .q3: scene.hero.perform(.glanceUp)
        case .preparing: say("Give me a moment…"); scene.focus = scene.flameFocus
        case .firstLight: say("Here's where we begin.")
        default: break
        }
        if s.rawValue >= IntroStep.q2.rawValue && s != .preparing && s != .firstLight { withAnimation { bubble = nil } }
    }

    private func setUpWorld() {
        guard model.sanctuaryBuilt, director == nil else { return }
        let d = AliveDirector(seed: 21, meter: meter); d.attach(scene.hero, tempo: 0.6); director = d
    }

    private func say(_ s: String) {
        withAnimation(.spring(duration: 0.4)) { bubble = s }
        scene.hero.react(.giggle)
        director?.mutter()
        FeelSound.shared.babble(syllables: min(7, max(3, s.count / 10)))
    }

    private func startWarming() {
        holding = true
        FeelHaptics.shared.startCharge(duration: 2.2); FeelSound.shared.startCharge(duration: 2.2, pitch: 2)
        warmFrom = warmAt(Date()); warmSince = Date()
        Task { @MainActor in
            while holding {                                     // only checks; the ember's look follows time itself
                warmth = warmAt(Date())
                if warmth >= 1 { hatch(); return }
                try? await Task.sleep(for: .milliseconds(40))
            }
        }
    }
    private func stopWarming() {
        guard holding, warmAt(Date()) < 1 else { return }
        warmFrom = warmAt(Date()); warmSince = Date()
        holding = false
        warmth = warmFrom
        FeelHaptics.shared.stopCharge(); FeelSound.shared.stopCharge()
    }
    private func hatch() {
        holding = false
        FeelHaptics.shared.stopCharge(); FeelSound.shared.stopCharge()
        FeelHaptics.shared.ignite(); FeelSound.shared.ignite(pitch: 2)
        withAnimation(.easeOut(duration: 0.4)) { rays = true }
        withAnimation(.easeOut(duration: 0.7)) { emberGone = 1 }
        if let e = ember { model.setEmber(e.id); scene.hero.tint = SparkTint.shift(e.id) }   // born in your ember's color
        go(.born)
        // Your Flame is born on the stone circle, and color floods back into the Sanctuary.
        scene.flameTarget = 1
        scene.hero.react(.cheer)
        Task { @MainActor in
            scene.fadeVitality(to: 1, over: 1.8)                              // color floods back, frame by frame
            try? await Task.sleep(for: .milliseconds(2400))
        }
        Task { try? await Task.sleep(for: .seconds(2.2)); withAnimation(.easeOut(duration: 1.2)) { rays = false } }
    }

    /// A glimpse of what the Spark will become: light gathers, it transforms through its stages (a breath each),
    /// then settles back into the little Spark it is today.
    private func glimpse() {
        glimpseDone = false
        Task { @MainActor in
            func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
            await wait(1.6)
            FeelHaptics.shared.startCharge(duration: 1.0); FeelSound.shared.startCharge(duration: 1.0, pitch: 3)
            withAnimation(.easeIn(duration: 0.5)) { morphFlash = 0.95 }
            await wait(0.5)
            scene.flameTarget = 0                                     // the living Spark gives way to the vision
            FeelHaptics.shared.stopCharge(); FeelSound.shared.stopCharge()
            for m in 1..<Self.stages.count {
                withAnimation(.easeInOut(duration: 0.35)) { morph = m; morphFlash = 0.35 }
                FeelHaptics.shared.nudge(); FeelSound.shared.chime(m + 1)
                await wait(m == Self.stages.count - 1 ? 1.4 : 0.9)
                withAnimation(.easeIn(duration: 0.2)) { morphFlash = 0.8 }
                await wait(0.2)
            }
            withAnimation(.easeOut(duration: 0.4)) { morph = nil; morphFlash = 0.9 }
            scene.flameTarget = 1                                     // back to the Spark, with its little spring
            FeelHaptics.shared.ignite(); FeelSound.shared.ignite(pitch: 3)
            withAnimation(.easeOut(duration: 0.9)) { morphFlash = 0 }
            scene.hero.react(.giggle)
            await wait(0.6)
            say("…but I'll grow as you grow.")
            withAnimation(.spring(duration: 0.5)) { glimpseDone = true }
        }
    }

    private func gotLight() {
        FeelHaptics.shared.ignite(); FeelSound.shared.catchLight()
        scene.hero.react(.cheer)
        say("Yes. And every real thing you do gives me light.")
        withAnimation(.spring(duration: 0.4)) { lightToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation { lightToast = false }
            go(.growing)
        }
    }

    private var firstThings: [String] {
        let picks = answers[1, default: []]
        let pool: [(String, String)] = [
            ("Be closer to people I love", "Tell someone why you admire them"),
            ("Read again", "Read ten pages of anything you like"),
            ("Find calm", "Three slow breaths, right now"),
            ("Move a little every day", "A ten-minute walk at an easy pace"),
            ("Make something / focus", "Twenty focused minutes on one thing"),
            ("Spend time in nature", "Step outside and notice one living thing"),
        ]
        var out = pool.filter { picks.contains($0.0) }.map(\.1)
        if let e = ember, let first = pool.first(where: { $0.0 == e.interest }), !out.contains(first.1) { out.insert(first.1, at: 0) }
        if out.isEmpty { out = ["Three slow breaths, right now"] }
        return Array(out.prefix(3))
    }

    private func finish() {
        if let e = ember { model.chose(e.interest); model.setEmber(e.id) }
        model.journey.born(name: name.trimmingCharacters(in: .whitespaces), ember: ember?.word ?? "light")   // the Book's first page
        FeelHaptics.shared.rise(); FeelSound.shared.rise()
        withAnimation { bubble = nil }
        scene.focus = nil                            // the camera pulls back: the whole Sanctuary
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            model.tour = .satchel                      // the guided tour: the Sanctuary, the map, the Grove
            withAnimation(.easeInOut(duration: 0.8)) { model.go(.home) }
        }
    }

    /// Simulator testing: plays the whole intro with taps.
    private func autoplay() {
        Task { @MainActor in
            func w(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
            await w(2); go(.chooseEmber); await w(1.5); ember = emberChoices[0]; await w(1.5); go(.warm)
            await w(1); startWarming(); await w(3)
            await w(3); go(.hello); await w(2); name = "Mathis"; await w(1); go(.whatAmI); await w(2.5); gotLight()
            await w(12); go(.world); await w(3.5); go(.mornings); await w(2); go(.q1)
            await w(2); answers[1] = ["Be closer to people I love", "Read again"]; await w(1); go(.q2)
            await w(1.5); answers[2] = ["About 15 minutes"]; go(.q3); await w(1.5); answers[3] = ["Just starting out"]; go(.preparing)
            await w(4.5); finish()
        }
    }
}

// MARK: - Reusable visuals

/// The dusk background: a soft violet → peach gradient with a few drifting embers.
struct DuskBackground: View {
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                    Gradient(colors: [Color(red: 0.24, green: 0.18, blue: 0.36), Color(red: 0.55, green: 0.36, blue: 0.5), Color(red: 0.93, green: 0.6, blue: 0.48)]),
                    startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
                for i in 0..<18 {
                    let s = Double(i) * 37.1
                    let x = (sin(s) * 0.5 + 0.5) * size.width + sin(t * 0.3 + s) * 12
                    let y = size.height - (CGFloat((t * (8 + Double(i % 5) * 3) + s * 40).truncatingRemainder(dividingBy: Double(size.height + 40))))
                    let r = 1.2 + Double(i % 3)
                    let a = 0.25 + 0.25 * sin(t * 2 + s)
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)), with: .color(Color(red: 1, green: 0.8, blue: 0.5).opacity(a)))
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// A glowing ember (the "egg"): breathing light; warmth makes it brighter; cracks spread across it as it warms.
struct EmberOrb: View {
    let color: Color, size: CGFloat, warmth: CGFloat, cracks: CGFloat
    @State private var breathe = false
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [color.opacity(0.55 + warmth * 0.3), .clear], center: .center, startRadius: 0, endRadius: size * (0.9 + warmth * 0.6)))
                .frame(width: size * 2.4, height: size * 2.4)
            Ellipse().fill(RadialGradient(colors: [.white, Color(red: 1, green: 0.85, blue: 0.55), color, color.opacity(0.85)], center: UnitPoint(x: 0.45, y: 0.4), startRadius: 1, endRadius: size * 0.6))
                .frame(width: size * 0.82, height: size)
                .overlay(Cracks(progress: cracks).stroke(Color.white.opacity(0.9), style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .shadow(color: .white, radius: 4).frame(width: size * 0.82, height: size))
        }
        .scaleEffect(breathe ? 1.04 : 0.97)
        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: breathe)
        .onAppear { breathe = true }
    }
}

nonisolated struct Cracks: Shape {
    var progress: CGFloat
    var animatableData: CGFloat { get { progress } set { progress = newValue } }
    func path(in r: CGRect) -> Path {
        var p = Path()
        let lines: [[CGPoint]] = [
            [CGPoint(x: 0.5, y: 0.08), CGPoint(x: 0.42, y: 0.25), CGPoint(x: 0.55, y: 0.38), CGPoint(x: 0.46, y: 0.55)],
            [CGPoint(x: 0.55, y: 0.38), CGPoint(x: 0.72, y: 0.45), CGPoint(x: 0.68, y: 0.6)],
            [CGPoint(x: 0.42, y: 0.25), CGPoint(x: 0.26, y: 0.3), CGPoint(x: 0.22, y: 0.45)],
            [CGPoint(x: 0.46, y: 0.55), CGPoint(x: 0.36, y: 0.7), CGPoint(x: 0.44, y: 0.84)],
        ]
        for (i, l) in lines.enumerated() {
            let start = CGFloat(i) * 0.22, k = min(1, max(0, (progress - start) / 0.35))
            guard k > 0 else { continue }
            let n = Int(ceil(CGFloat(l.count - 1) * k))
            p.move(to: CGPoint(x: l[0].x * r.width, y: l[0].y * r.height))
            for j in 1...max(1, n) { p.addLine(to: CGPoint(x: l[min(j, l.count - 1)].x * r.width, y: l[min(j, l.count - 1)].y * r.height)) }
        }
        return p
    }
}

/// Finch-style light rays behind the newborn Flame.
struct LightRays: View {
    let on: Bool
    @State private var spin = false
    var body: some View {
        ZStack {
            ForEach(0..<14, id: \.self) { i in
                Rectangle().fill(LinearGradient(colors: [Color(red: 1, green: 0.9, blue: 0.65).opacity(0.55), .clear], startPoint: .bottom, endPoint: .top))
                    .frame(width: 34, height: 520).offset(y: -260).rotationEffect(.degrees(Double(i) * 360 / 14))
            }
        }
        .rotationEffect(.degrees(spin ? 30 : 0))
        .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: spin)
        .opacity(on ? 1 : 0).scaleEffect(on ? 1 : 0.4)
        .position(x: UIScreen.main.bounds.width / 2, y: 250)
        .onAppear { spin = true }
    }
}

/// The hatching (replaces the star rays): a warm bloom of light swells from the ember on the circle and fades,
/// while embers drift upward like sparks from a fire waking up.
struct BirthBloom: View {
    let on: Bool
    var center: CGPoint? = nil
    @State private var t: Double = 0
    var body: some View {
        TimelineView(.animation(paused: !on && t == 0)) { tl in
            Canvas { ctx, size in
                guard t > 0 else { return }
                let c = center ?? CGPoint(x: size.width / 2, y: size.height * 0.5)
                let k = min(1, t / 1.8)
                // The bloom: grows quickly, then softly fades.
                let r = 40 + 380 * (1 - pow(1 - k, 3))
                let a = (k < 0.25 ? k / 0.25 : max(0, 1 - (k - 0.25) / 0.75)) * 0.85
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r * 0.8, width: r * 2, height: r * 1.6)),
                         with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.95, blue: 0.8).opacity(a), Color(red: 1, green: 0.7, blue: 0.35).opacity(a * 0.5), .clear]),
                                               center: c, startRadius: 0, endRadius: r))
                // Embers rising and drifting outward.
                for i in 0..<34 {
                    let s = Double(i) * 12.9898
                    let life = min(1, max(0, (t - Double(i % 6) * 0.05) / 2.4))
                    guard life > 0 && life < 1 else { continue }
                    let ang = (sin(s) * 0.5 + 0.5) * .pi * 2
                    let dist = 40 + 220 * life * (0.5 + 0.5 * cos(s * 1.3))
                    let x = c.x + cos(ang) * dist * 0.7 + sin(t * 3 + s) * 6
                    let y = c.y + sin(ang) * dist * 0.35 - 260 * life * (0.6 + 0.4 * sin(s * 0.7))
                    let rr = 2.2 * (1 - life) + 0.8
                    ctx.fill(Path(ellipseIn: CGRect(x: x - rr, y: y - rr, width: rr * 2, height: rr * 2)),
                             with: .color(Color(red: 1, green: 0.8, blue: 0.45).opacity((1 - life) * 0.95)))
                }
            }
            .onChange(of: tl.date) { _, _ in if on || t > 0 { t += 1.0 / 60; if t > 3 && !on { t = 0 } } }
        }
        .ignoresSafeArea()
    }
}
