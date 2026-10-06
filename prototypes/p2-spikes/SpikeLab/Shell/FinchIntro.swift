// The introduction (decision 140, docs/plan-2.0/p26-intro-redesign.md, after studying Finch, Duolingo, Headspace,
// Calm, Life Reset and Fabulous): the Hush → choose your ember → warm it, it hatches → the Spark comes alive and
// asks your name → the glimpse of what it will become, in shadow → why you're here → where you stand (your Day 1
// rating) → your daily moment → preparing your path → your starting light (first quests picked) → the first light,
// done together → a small promise → your mornings → home. No account, no paywall, data only after the bond.
import SwiftUI
import RealityKit
import UserNotifications

enum IntroStep: Int, CaseIterable { case welcome, chooseEmber, warm, born, hello, growing, why, stand, moment, preparing, startingLight, firstDeed, promise, mornings }

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
    @State private var firstOutcome: DeedOutcome?
    @State private var hatchStart: Date?
    @State private var opened = false
    @State private var rating: [Pillar6: Int] = [:]      // where you stand (0 low, 1 okay, 2 good): the Day 1 rating
    @State private var meetWhen: String?
    @State private var meetFor: String?
    @State private var prepDone = 0
    @State private var reps = 0
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
                            let eggSize = max(60, f.height * 0.55)
                            if step == .warm {
                                WarmRing(warmth: w, holding: holding, size: eggSize * 1.55)
                                    .position(x: f.feet.x, y: f.feet.y - eggSize * 0.5)
                            }
                            EggView(color: ember?.color ?? gold, size: eggSize, warmth: w)
                                .scaleEffect((holding ? 1.06 + w * 0.08 : 1) * (1 + emberGone * 0.6))
                                .opacity(1 - emberGone)
                                .offset(x: holding ? sin(tl.date.timeIntervalSinceReferenceDate * 47) * w * 2.5 : 0)   // a smooth tremble
                                .position(x: f.feet.x, y: f.feet.y - max(60, f.height * 0.55) * 0.5)
                                .gesture(DragGesture(minimumDistance: 0).onChanged { _ in if !holding { startWarming() } }.onEnded { _ in stopWarming() })
                        }
                        if let hs = hatchStart {
                            HatchBurst(start: hs, center: CGPoint(x: f.feet.x, y: f.feet.y - max(60, f.height * 0.55) * 0.5), color: ember?.color ?? gold)
                        }
                        if let m = morph {
                            let h = f.height * Self.stageHeights[m] / Self.stageHeights[0] * 0.95
                            // In shadow: only the outline of what it will become, edged with a faint warm light
                            // (the future stays a mystery until it's lived).
                            Image(uiImage: UIImage(named: "\(Self.stages[m]).png") ?? UIImage()).resizable()
                                .renderingMode(.template).scaledToFit()
                                .foregroundStyle(LinearGradient(colors: [Color(red: 0.16, green: 0.1, blue: 0.2), Color(red: 0.07, green: 0.05, blue: 0.12)], startPoint: .top, endPoint: .bottom))
                                .shadow(color: Color(red: 1, green: 0.7, blue: 0.4).opacity(0.85), radius: 2)
                                .shadow(color: Color(red: 1, green: 0.55, blue: 0.25).opacity(0.5), radius: 18)
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
                if step.rawValue >= IntroStep.why.rawValue && step.rawValue <= IntroStep.moment.rawValue { progressBar.padding(.top, 8) }
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
            if let o = firstOutcome, step == .firstDeed {
                RewardBurst(outcome: o) { go(.promise) }
            }
        }
        .animation(.smooth(duration: 0.38), value: step)
        .onAppear {
            meter.start()
            scene.hideFlameInstantly()                      // not born yet
            scene.setVitality(worldVitality)
            setUpWorld()
            if CommandLine.arguments.contains("-autointro") { autoplay() }
            let a = CommandLine.arguments                        // (test: -introstep <beat> opens the intro on that beat)
            if let i = a.firstIndex(of: "-introstep"), i + 1 < a.count, let st = IntroStep.allCases.first(where: { "\($0)" == a[i + 1] }) {
                ember = emberChoices[0]; name = "Mathis"; scene.flameTarget = 1; scene.setVitality(0.5)
                if st.rawValue > IntroStep.stand.rawValue { for p in Pillar6.allCases { rating[p] = 1 } ; rating[.body] = 0 }
                go(st)
            }
        }
        .onChange(of: model.sanctuaryBuilt) { _, _ in scene.setVitality(worldVitality); setUpWorld() }
        .onDisappear { meter.stop(); director?.stop() }     // home's own director takes over the same Spark
    }

    // MARK: Screens

    @ViewBuilder private var content: some View {
        switch step {
        case .welcome:
            VStack(spacing: 14) {
                Spacer()
                // The title rises out of the haze, then the line, then the button: one breath each.
                Text("Hush").font(.story(60, .semibold)).tracking(opened ? 4 : 18).foregroundStyle(cream)
                    .shadow(color: Color(red: 1, green: 0.62, blue: 0.3).opacity(0.55), radius: 18).shadow(color: .black.opacity(0.4), radius: 10)
                    .opacity(opened ? 1 : 0).blur(radius: opened ? 0 : 14).scaleEffect(opened ? 1 : 1.08)
                    .animation(.easeOut(duration: 2.2), value: opened)
                body2("The world went quiet. One ember still waits.")
                    .opacity(opened ? 1 : 0).animation(.easeOut(duration: 1.2).delay(1.4), value: opened)
                Spacer().frame(height: 26)
                primary("Wake it") { go(.chooseEmber) }
                    .opacity(opened ? 1 : 0).offset(y: opened ? 0 : 12).animation(.spring(duration: 0.8).delay(2.3), value: opened)
                Text("Private test · for adults 18+").font(.caption2).foregroundStyle(cream.opacity(0.4)).padding(.top, 6)
                    .opacity(opened ? 1 : 0).animation(.easeOut.delay(2.6), value: opened)
            }
            .onAppear { opened = true }
        case .chooseEmber:
            VStack(spacing: 14) {
                title("Which light calls you?")
                body2("Your Flame will carry its colour. Every light can grow later.")
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
            Spacer().frame(height: 80)
        case .hello:
            VStack(spacing: 14) {
                // Your name, written on a single hairline (nothing else around it).
                VStack(spacing: 6) {
                    TextField("", text: $name, prompt: Text("Your name").italic().foregroundColor(cream.opacity(0.35)))
                        .font(.story(32, .medium)).multilineTextAlignment(.center).foregroundStyle(cream).tint(Theme.champagne)
                        .shadow(color: Theme.warmShadow.opacity(0.8), radius: 6)
                    Rectangle().fill(LinearGradient(colors: [.clear, Theme.champagne.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 0.75)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 8)
                    .focused($typing).submitLabel(.done).onSubmit { if !name.isEmpty { go(.growing) } }
                primary("That's me", disabled: name.trimmingCharacters(in: .whitespaces).isEmpty) { go(.growing) }
            }
        case .growing:
            VStack(spacing: 16) {
                if glimpseDone { primary("Next") { go(.why) } } else { Spacer().frame(height: 60) }
            }
        case .why:
            question("What brings you here?", sub: "Pick as many as you like", options: emberChoices.map(\.interest), multi: true, key: 1, next: .stand)
        case .stand:
            standCard
        case .moment:
            momentCard
        case .preparing:
            VStack(alignment: .leading, spacing: 12) {
                title("Preparing your path…")
                ForEach(Array(["Reading your answers", "Choosing your first quests", "Waking your Sanctuary"].enumerated()), id: \.offset) { i, t in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().stroke(gold.opacity(0.4), lineWidth: 2).frame(width: 22, height: 22)
                            if prepDone > i { Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy)).foregroundStyle(gold).transition(.scale) }
                        }
                        Text(t).font(.ui(16, .semibold)).foregroundStyle(cream.opacity(prepDone >= i ? 1 : 0.4))
                    }
                }
                Spacer().frame(height: 30)
            }
            .task {
                async let ready: Void = model.preloadCore()          // the worlds really get ready here
                for i in 1...3 {
                    try? await Task.sleep(for: .milliseconds(i == 3 ? 500 : 800))
                    if i == 3 { await ready }
                    withAnimation(.spring(duration: 0.35)) { prepDone = i }
                    FeelHaptics.shared.nudge()
                }
                scene.hero.react(.cheer); FeelSound.shared.chime(4)
                try? await Task.sleep(for: .milliseconds(500)); go(.startingLight)
            }
        case .startingLight:
            startingCard
        case .firstDeed:
            VStack(spacing: 16) {
                if weakest == .body {
                    RepCounter(count: $reps, target: 5, word: "squats", color: gold) { firstDeedDone() }.frame(width: 210, height: 210)
                } else {
                    BreathCircle(breaths: 3, color: gold) { firstDeedDone() }.frame(width: 210, height: 210)
                }
                if firstOutcome == nil { secondary("I did it") { firstDeedDone() } }
            }
        case .promise:
            VStack(spacing: 12) {
                title("Keep your flame alive for 7 days?")
                body2("At day 7 you earn a shield: one missed day won't put your flame out.")
                primary("I'm in") { journeyPromise(7); go(.mornings) }
                secondary("Let's just begin") { go(.mornings) }
            }
        case .mornings:
            VStack(spacing: 12) {
                title("Shall I bring you your day?")
                body2("A gentle note each \(meetWord) at \(meetTimeText). Nothing else, ever.")
                primary("Yes, please") { askReminders() }
                secondary("Not now") { finish() }
            }
        }
    }

    // MARK: The question cards (where you stand, your moment, your starting light)

    private var standCard: some View {
        VStack(spacing: 10) {
            Text("How is each part of your life lately?").font(.story(22, .medium)).multilineTextAlignment(.center).foregroundStyle(Theme.ink)
            Text("Only you see this. It stays on your phone.").font(.ui(13)).foregroundStyle(Theme.ink.opacity(0.55))
            HStack(spacing: 22) {
                Spacer(minLength: 0)
                ForEach(["low", "okay", "good"], id: \.self) { t in Text(t).font(.story(13).italic()).foregroundStyle(Theme.ink.opacity(0.5)).frame(width: 36) }
            }
            .padding(.top, 6)
            ForEach(Pillar6.allCases, id: \.self) { p in
                HStack(spacing: 8) {
                    Image(uiImage: UIImage(named: "pillar-\(p.rawValue.lowercased()).png") ?? UIImage()).resizable().scaledToFit().frame(width: 30, height: 30)
                    Text(p.rawValue).font(.story(15, .semibold)).foregroundStyle(Theme.ink).frame(width: 54, alignment: .leading)
                    Spacer(minLength: 0)
                    HStack(spacing: 22) {                               // three quiet marks: low, okay, good
                        ForEach(0..<3, id: \.self) { v in
                            Button {
                                FeelHaptics.shared.nudge()
                                withAnimation(Motion.tap) { rating[p] = v }
                                scene.hero.react(v == 0 ? .giggle : .cheer)
                            } label: {
                                ZStack {
                                    Circle().stroke(Theme.paperEdge.opacity(0.5), lineWidth: 0.75).frame(width: 22, height: 22)
                                    Circle().fill(Theme.champagneDeep).frame(width: rating[p] == v ? 14 : 0, height: rating[p] == v ? 14 : 0)
                                }
                                .frame(width: 36, height: 34).contentShape(Rectangle())
                            }
                        }
                    }
                }
            }
            primary("Next", disabled: rating.count < 6) { go(.moment) }.padding(.top, 4)
        }
        .padding(18)
        .background(SheetPaper(corner: 26))
        .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
    }

    private var momentCard: some View {
        VStack(spacing: 12) {
            Text("When can we meet each day?").font(.story(22, .medium)).multilineTextAlignment(.center).foregroundStyle(Theme.ink)
            chips(["Morning", "Midday", "Evening"], selected: meetWhen) { meetWhen = $0 }
            Text("And for how long?").font(.story(16)).foregroundStyle(Theme.ink.opacity(0.8)).padding(.top, 4)
            chips(["5 min", "15 min", "30 min"], selected: meetFor) { meetFor = $0 }
            primary("Next", disabled: meetWhen == nil || meetFor == nil) { go(.preparing) }.padding(.top, 4)
        }
        .padding(18)
        .background(SheetPaper(corner: 26))
        .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
    }

    private func chips(_ options: [String], selected: String?, pick: @escaping (String) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { o in
                Button {
                    FeelHaptics.shared.nudge(); withAnimation(.spring(duration: 0.25)) { pick(o) }
                    if let line = Self.replies[o] { say(line) } else { scene.hero.react(.giggle) }
                } label: {
                    ParchmentChoice(text: o, selected: selected == o, compact: true)
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    private var startingCard: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 9) {
                Text("Your starting light").font(.story(22)).foregroundStyle(Theme.ink)
                HStack(alignment: .bottom, spacing: 0) {                 // your six lights, as big as they are today
                    ForEach(Pillar6.allCases, id: \.self) { p in
                        VStack(spacing: 3) {
                            Image(systemName: "flame.fill").font(.system(size: 14 + CGFloat(rating[p] ?? 1) * 9))
                                .foregroundStyle(LinearGradient(colors: [p.realm.color.opacity(0.9), Theme.accent], startPoint: .top, endPoint: .bottom))
                            Text(p.rawValue).font(.ui(10, .semibold)).foregroundStyle(Theme.ink.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 54)
                startLine("sun.max.fill", "Your strongest", strongest.rawValue)
                startLine("arrow.up.forward", "Where we start", weakest.rawValue)
                Divider().overlay(Theme.paperEdge.opacity(0.5)).padding(.vertical, 2)
                Text("Your first quests, picked for you").font(.ui(13, .bold)).foregroundStyle(Theme.accent)
                ForEach(model.calls.filter(\.chosen)) { c in
                    HStack(spacing: 10) {
                        Image(systemName: c.symbol).font(.system(size: 13, weight: .semibold)).foregroundStyle(c.realm.color)
                            .frame(width: 26, height: 26).background(Circle().fill(Theme.night.opacity(0.85)))
                        Text(c.title).font(.ui(15, .semibold)).foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(c.minutes) min").font(.ui(12)).foregroundStyle(Theme.ink.opacity(0.55))
                    }
                }
                Text("Day 1 of 66 · swap any quest in your satchel").font(.ui(11)).foregroundStyle(Theme.ink.opacity(0.5))
            }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(SheetPaper(corner: 22))
            primary("Light the first one with me") { go(.firstDeed) }
        }
    }

    /// Where you stand: the pillar you feel best in, and the one we'll start with (the lowest; ties go to your
    /// ember's pillar, then the order of the pillars).
    private var strongest: Pillar6 { Pillar6.allCases.max { (rating[$0] ?? 1) < (rating[$1] ?? 1) } ?? .heart }
    private var weakest: Pillar6 {
        let low = Pillar6.allCases.map { rating[$0] ?? 1 }.min() ?? 1
        let ties = Pillar6.allCases.filter { (rating[$0] ?? 1) == low }
        if let e = ember, let mine = ties.first(where: { $0.rawValue == e.pillar }) { return mine }
        return ties.first ?? .spirit
    }
    private var meetWord: String { (meetWhen ?? "Morning").lowercased() }
    private var meetHour: Int { ["Morning": 8, "Midday": 12, "Evening": 19][meetWhen ?? "Morning"] ?? 8 }
    private var meetTimeText: String { meetHour == 12 ? "12:30" : "\(meetHour):00" }
    private func journeyPromise(_ days: Int) { model.journey.setUp(dayOne: [:], meetHour: nil, promise: days) }

    /// The reminder, asked last (once the value is felt), at the moment you chose. A local note: no server.
    private func askReminders() {
        let hour = meetHour
        Task { @MainActor in
            let c = UNUserNotificationCenter.current()
            if (try? await c.requestAuthorization(options: [.alert, .sound])) == true {
                let content = UNMutableNotificationContent()
                content.title = "Your day is ready"; content.body = "Your Flame has your quests. One small thing keeps it burning."
                var when = DateComponents(); when.hour = hour; when.minute = hour == 12 ? 30 : 0
                try? await c.add(UNNotificationRequest(identifier: "daily", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: true)))
            }
            finish()
        }
    }

    private func startLine(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(Theme.accent).frame(width: 16)
            Text(label).font(.ui(13)).foregroundStyle(Theme.ink.opacity(0.6))
            Text(value).font(.ui(14, .bold)).foregroundStyle(Theme.ink)
        }
    }

    /// The first win, inside the introduction: three slow breaths, really done; the light flies, XP and Day 1.
    private func firstDeedDone() {
        guard firstOutcome == nil else { return }
        let o = weakest == .body
            ? model.journey.did("Five squats", detail: "Your very first light.", realm: .highlands, minutes: 1)
            : model.journey.did("Three slow breaths", detail: "Your very first light.", realm: .stillwater, minutes: 1)
        FeelHaptics.shared.ignite(); FeelSound.shared.catchLight()
        scene.hero.react(.cheer)
        say("You did it. That's my first light!")
        withAnimation(.spring(duration: 0.4)) { firstOutcome = o }
        scene.fadeVitality(to: 1, over: 2.4)               // and the Sanctuary wakes, all its colour back
    }

    // MARK: Pieces

    private func title(_ s: String) -> some View {
        Text(s).font(.story(28, .medium)).multilineTextAlignment(.center).foregroundStyle(cream)
            .shadow(color: .black.opacity(0.45), radius: 8).shadow(color: Color(red: 1, green: 0.6, blue: 0.25).opacity(0.25), radius: 16)
    }
    private func body2(_ s: String) -> some View {
        Text(s).font(.ui(16)).multilineTextAlignment(.center).foregroundStyle(cream.opacity(0.78))
    }
    private func primary(_ s: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button { FeelHaptics.shared.nudge(); action() } label: { GoldButtonLabel(text: s) }
            .buttonStyle(PressableStyle())
            .disabled(disabled).opacity(disabled ? 0.5 : 1).saturation(disabled ? 0.4 : 1)
    }
    private func secondary(_ s: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { QuietLink(text: s) }.buttonStyle(PressableStyle())
    }
    private func choice(_ s: String, icon: UIImage? = nil, selected: Bool = false, action: @escaping () -> Void) -> some View {
        Button { FeelHaptics.shared.nudge(); action() } label: { ParchmentChoice(text: s, icon: icon, selected: selected) }
            .buttonStyle(PressableStyle())
    }

    private func question(_ q: String, sub: String?, options: [String], multi: Bool, key: Int, next: IntroStep) -> some View {
        questionBody(q, sub: sub, options: options, multi: multi, key: key, next: next)
            .padding(18)
            .background(SheetPaper(corner: 26))
            .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
    }

    private func questionBody(_ q: String, sub: String?, options: [String], multi: Bool, key: Int, next: IntroStep) -> some View {
        VStack(spacing: 10) {
            Text(q).font(.story(23, .medium)).multilineTextAlignment(.center).foregroundStyle(Theme.ink)
            if let sub { Text(sub).font(.ui(14)).foregroundStyle(Theme.ink.opacity(0.6)) }
            Spacer().frame(height: 6)
            let columns = multi ? [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)] : [GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 10) {
            ForEach(options, id: \.self) { o in
                choice(multi ? shortLabel(o) : o, icon: emberChoices.first(where: { $0.interest == o }).flatMap { UIImage(named: "pillar-\($0.pillar.lowercased()).png") },
                       selected: answers[key, default: []].contains(o)) {
                    var set = answers[key, default: []]
                    if multi { if set.contains(o) { set.remove(o) } else { set.insert(o) } } else { set = [o] }
                    answers[key] = set
                    scene.hero.react(.giggle)
                    if let line = Self.replies[o] { say(line) }
                    if !multi { Task { try? await Task.sleep(for: .milliseconds(350)); go(next) } }
                }
            }
            }
            if multi { primary("Next", disabled: answers[key, default: []].isEmpty) { go(next) }.padding(.top, 6) }
        }
    }

    /// The Spark answers what you pick (a few words, warm, never judging).
    private static let replies: [String: String] = [
        "About 5 minutes": "Five good minutes is plenty.", "About 15 minutes": "Fifteen minutes. We can do a lot with that.",
        "Half an hour": "Half an hour! Lovely.", "More than that": "Then we'll go far, gently.",
        "Just starting out": "Starting is the bravest part.", "I have a few good habits": "Good. We'll build on them.",
        "I'm already quite active": "Then I'll keep up with you.",
        "Morning": "Mornings! I'll be up early.", "Midday": "A pause in the middle of the day. Nice.", "Evening": "Evenings, when it's quiet.",
        "5 min": "Five good minutes is plenty.", "15 min": "Fifteen minutes. We can do a lot.", "30 min": "Half an hour! Lovely.",
        "Be closer to people I love": "People. The warmest light.", "Read again": "Books! I love stories.",
        "Move a little every day": "Let's get moving.", "Find calm": "Calm. Yes, please.",
        "Make something / focus": "Making things. Good.", "Spend time in nature": "Out there it's waiting.",
    ]

    private func shortLabel(_ o: String) -> String {
        ["Be closer to people I love": "People I love", "Read again": "Reading", "Find calm": "Calm",
         "Move a little every day": "Moving", "Make something / focus": "Making & focus", "Spend time in nature": "Nature"][o] ?? o
    }

    private var progressBar: some View {
        let k = CGFloat(step.rawValue - IntroStep.why.rawValue + 1) / 3
        return Capsule().fill(.white.opacity(0.12)).frame(height: 2)
            .overlay(alignment: .leading) { GeometryReader { g in Capsule().fill(Theme.champagne.opacity(0.85)).frame(width: g.size.width * k) } }
            .animation(Motion.gentle, value: k)
            .padding(.horizontal, 90)
    }

    private var emberRing: some View {
        GeometryReader { g in
            let c = CGPoint(x: g.size.width / 2, y: g.size.height / 2), r = min(g.size.width, g.size.height) * 0.38
            ZStack {
                EmberOrb(color: ember?.color ?? gold.opacity(0.6), size: 74, warmth: ember == nil ? 0.08 : 0.35, cracks: 0)
                    .opacity(ember == nil ? 0.5 : 0.9)
                    .position(c).animation(.spring(duration: 0.5), value: ember)
                ForEach(Array(emberChoices.enumerated()), id: \.element.id) { i, e in
                    let a = Double(i) / 6 * 2 * .pi - .pi / 2
                    Button {
                        withAnimation(.spring(duration: 0.4)) { ember = e }
                        FeelHaptics.shared.nudge(); FeelSound.shared.chime(i)
                    } label: {
                        VStack(spacing: 6) {
                            EmberOrb(color: e.color, size: ember == e ? 54 : 44, warmth: ember == e ? 0.6 : 0.25, cracks: 0)
                            Text(e.word).font(.story(14, .medium).italic()).foregroundStyle(cream).opacity(ember == e ? 1 : 0)
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
            StoryBubble(text: s)
                .padding(.horizontal, 34)
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
        case .born:
            bubble = nil
            Task { try? await Task.sleep(for: .seconds(2.4)); if step == .born { go(.hello) } }   // it wakes, then speaks
        case .hello: say("…Oh! Hi. You woke me. What should I call you?")
        case .growing: say("I'm small now. If we live well together, one day I'll become…"); glimpse()
        case .why: say("So, \(name.trimmingCharacters(in: .whitespaces)). What brings you here?")
            scene.focus = scene.flameFocus - SIMD3(0, 0.085, 0)   // aim lower: the Flame watches from above the questions
        case .stand: say("And how are you, really?"); scene.hero.perform(.glanceUp)
        case .moment: say("When shall we meet?"); scene.hero.perform(.glanceUp)
        case .preparing: say("Give me a moment…"); scene.focus = scene.flameFocus
        case .startingLight:
            // You exist from here: your ember, your Day 1 rating, your moment, your first quests (never a blank day).
            if let e = ember { model.chose(e.interest); model.setEmber(e.id) }
            pickFirstQuests()
            if model.journey.pages.isEmpty { model.journey.born(name: name.trimmingCharacters(in: .whitespaces), ember: ember?.word ?? "light") }
            model.journey.setUp(dayOne: Dictionary(uniqueKeysWithValues: rating.map { ($0.key.rawValue, $0.value) }), meetHour: meetHour, promise: nil)
            say("Here's where we begin.")
        case .firstDeed: say(weakest == .body ? "Let's do one together. Five squats, with me." : "Let's do one together. Breathe with me.")
        case .promise: say("That's how the world wakes. One real thing at a time.")
        case .mornings: say("One last thing…")
        default: break
        }
        if s == .stand || s == .moment { withAnimation { bubble = nil } }
    }

    /// Your first three quests: the one for why you came, one for the pillar we start with, then a gentle one.
    private func pickFirstQuests() {
        guard model.chosenCount == 0 else { return }
        model.toggleChosen("a")
        if let c = model.calls.first(where: { !$0.chosen && !$0.done && Pillar6.of($0.realm) == weakest }) { model.toggleChosen(c.id) }
        for id in ["c", "d", "e", "b"] where model.chosenCount < ShellModel.maxChosen { model.toggleChosen(id) }
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
        hatchStart = Date()                                         // the burst: flash, shockwave, shards, embers
        Task { try? await Task.sleep(for: .seconds(2.7)); hatchStart = nil }
        withAnimation(.easeOut(duration: 0.7)) { emberGone = 1 }
        if let e = ember { model.setEmber(e.id); scene.hero.tint = SparkTint.shift(e.id) }   // born in your ember's color
        go(.born)
        // Your Flame is born on the stone circle, and color floods back into the Sanctuary.
        scene.flameTarget = 1
        scene.hero.react(.cheer)
        Task { @MainActor in
            scene.fadeVitality(to: 0.5, over: 1.8)        // some colour comes back; the rest waits for your first light
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
            say("…only real days can tell.")
            withAnimation(.spring(duration: 0.5)) { glimpseDone = true }
        }
    }

    private func finish() {
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
            await w(1); startWarming(); await w(6)
            await w(3); name = "Mathis"; await w(1); go(.growing)
            await w(12); go(.why)
            await w(2); answers[1] = ["Be closer to people I love", "Read again"]; await w(1); go(.stand)
            await w(1.5); for (i, p) in Pillar6.allCases.enumerated() { rating[p] = [1, 2, 0, 1, 1, 2][i] }; await w(1.5); go(.moment)
            await w(1.5); meetWhen = "Morning"; meetFor = "15 min"; await w(1); go(.preparing)
            await w(3.5); await w(3); go(.firstDeed); await w(3); firstDeedDone(); await w(4); go(.mornings); await w(2); finish()
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

/// Breathe with the Spark: a soft light grows as you breathe in (4 s) and settles as you breathe out (5 s), three
/// times, then the quest is done. (The longer out-breath is what calms; the counting keeps the mind on it.)
struct BreathCircle: View {
    let breaths: Int
    let color: Color
    let done: () -> Void
    @State private var grow = false
    @State private var count = 0
    @State private var inhaling = true
    var body: some View {
        ZStack {
            Circle().fill(Theme.night.opacity(0.55))                    // reads on the bright stone circle
            Circle().fill(RadialGradient(colors: [color.opacity(0.75), color.opacity(0.15), .clear], center: .center, startRadius: 4, endRadius: 105))
                .scaleEffect(grow ? 1 : 0.45)
            Circle().stroke(Theme.cream.opacity(0.85), lineWidth: 2.5).scaleEffect(grow ? 0.95 : 0.42)
            VStack(spacing: 4) {
                Text(count >= breaths ? "Done" : (inhaling ? "Breathe in" : "Breathe out")).font(.story(22)).foregroundStyle(Theme.cream)
                Text("\(min(count + 1, breaths)) of \(breaths)").font(.ui(13, .semibold)).foregroundStyle(Theme.cream.opacity(0.7))
            }
            .contentTransition(.opacity)
        }
        .task {
            for i in 0..<breaths {
                count = i
                withAnimation(.easeInOut(duration: 0.3)) { inhaling = true }
                FeelHaptics.shared.nudge()
                withAnimation(.easeInOut(duration: 4)) { grow = true }
                try? await Task.sleep(for: .seconds(4))
                withAnimation(.easeInOut(duration: 0.3)) { inhaling = false }
                withAnimation(.easeInOut(duration: 5)) { grow = false }
                try? await Task.sleep(for: .seconds(5))
            }
            count = breaths
            done()
        }
    }
}

extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}

/// Five squats with the Spark: tap after each one; the ring fills and the count climbs.
struct RepCounter: View {
    @Binding var count: Int
    let target: Int
    let word: String
    let color: Color
    let done: () -> Void
    var body: some View {
        Button {
            guard count < target else { return }
            FeelHaptics.shared.nudge()
            withAnimation(.spring(duration: 0.3)) { count += 1 }
            if count >= target { done() }
        } label: {
            ZStack {
                Circle().fill(Theme.night.opacity(0.55))
                Circle().stroke(Theme.cream.opacity(0.2), lineWidth: 8)
                Circle().trim(from: 0, to: CGFloat(count) / CGFloat(target)).stroke(color, style: .init(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(count)").font(.num(54, .heavy)).foregroundStyle(Theme.cream).contentTransition(.numericText())
                    Text(count >= target ? "Done!" : "tap after each of \(target) \(word)").font(.ui(13, .semibold)).foregroundStyle(Theme.cream.opacity(0.75))
                }
            }
        }
        .buttonStyle(PressableStyle())
    }
}

/// The egg: Codex's painted ember egg (three stages of cracks, tools/p28 art) when it's in the app, the drawn ember
/// until then. It glows brighter and cracks further as you warm it.
struct EggView: View {
    let color: Color
    let size: CGFloat
    let warmth: CGFloat
    var body: some View {
        if let img = UIImage(named: warmth < 0.4 ? "egg-0.png" : warmth < 0.8 ? "egg-1.png" : "egg-2.png") {
            ZStack {
                Circle().fill(RadialGradient(colors: [color.opacity(0.35 + warmth * 0.45), .clear], center: .center, startRadius: 0, endRadius: size * (0.8 + warmth * 0.6)))
                    .frame(width: size * 2.4, height: size * 2.4)
                Image(uiImage: img).resizable().scaledToFit().frame(height: size)
                    .shadow(color: color.opacity(0.4 + warmth * 0.5), radius: 8 + warmth * 16)
            }
        } else {
            EmberOrb(color: color, size: size, warmth: warmth, cracks: warmth)
        }
    }
}
