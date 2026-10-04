// The intro (Part 3 §11, decision 86): darkness and an ember → touch and hold → the Spark appears in the Sanctuary
// → the First Words, in Emberspeak melting into English → the world grows grey while it speaks of the Hush, and warm
// again with "light wakes things up" → the first question → home.
import SwiftUI
import RealityKit

struct FirstWordsLine { let text: String; let hush: Float? }

let firstWords: [FirstWordsLine] = [
    .init(text: "…Hm? Oh. There you are.", hush: nil),
    .init(text: "I'm your Flame. The part of you that's alive.", hush: nil),
    .init(text: "Every real thing you do — a walk, a page, a kind word — becomes light. Light is what I'm made of.", hush: nil),
    .init(text: "I don't grow when you tap things. I grow when you grow. Slowly, truly. And what we build is never lost.", hush: nil),
    .init(text: "Out there, the world got very loud. Everything pulls at you. Days slip by on autopilot.", hush: 0.35),
    .init(text: "Here, we call it the Hush. It turned whole lands grey, and it makes flames forget themselves.", hush: 0.15),
    .init(text: "But light wakes things up. Even out there. Even in you.", hush: 1),
    .init(text: "One day, I'll walk those roads. Climb the Highlands. Relight the old Beacons. Maybe even see what's beyond the Veil.", hush: nil),
    .init(text: "This place is a tool, not a cage. Come for a minute, then go live. I'll carry the light.", hush: nil),
    .init(text: "Talking is hard when you're this small. I'll learn. …Let's find your first light.", hush: nil),
]

let interests = ["Be closer to people I love", "Read again", "Find calm", "Move a little every day",
                 "Make something / focus", "Spend time in nature"]

struct IntroView: View {
    let model: ShellModel
    @State private var stage = 0            // 0 ember, 1 hatching, 2 words, 3 question, 4 answer
    @State private var hold: CGFloat = 0
    @State private var holding = false
    @State private var line = 0
    @State private var flash = false
    @State private var scene = SanctuaryScene()
    @State private var meter = FrameMeter()
    @State private var director: AliveDirector?
    @State private var holdTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if stage >= 1 {
                RealityView { content in
                    content.camera = .virtual
                    scene.flameTarget = 0
                    do { try await scene.build() } catch { return }
                    content.add(scene.root)
                    scene.setVitality(1)
                    let d = AliveDirector(seed: 3, meter: meter)
                    d.attach(scene.hero, tempo: 0.55)
                    director = d
                    scene.updates = content.subscribe(to: SceneEvents.Update.self) { e in scene.update(dt: Float(e.deltaTime)) }
                    try? await Task.sleep(for: .seconds(0.6))
                    scene.flameTarget = 1                       // the Spark appears with a spring
                    scene.hero.react(.cheer)
                    try? await Task.sleep(for: .seconds(1.2))
                    withAnimation(.easeOut(duration: 0.6)) { stage = 2 }
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
            if stage == 0 { ember }
            if stage == 2 { wordsPlate }
            if stage == 3 { question }
            Color.white.opacity(flash ? 0.9 : 0).ignoresSafeArea().allowsHitTesting(false)
        }
        .onAppear { meter.start() }
    }

    // MARK: Darkness and an ember
    private var ember: some View {
        VStack(spacing: 40) {
            Spacer()
            Text("Every person carries a flame.\nMost never see it.")
                .font(.story(20)).italic()
                .multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.75))
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(red: 1, green: 0.8, blue: 0.4), Color(red: 1, green: 0.4, blue: 0.1).opacity(0.6), .clear],
                                             center: .center, startRadius: 2, endRadius: 60 + 30 * hold))
                    .frame(width: 200, height: 200)
                    .scaleEffect(holding ? 1.15 + 0.2 * hold : 1)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: holding)
                Circle().trim(from: 0, to: hold).stroke(Color(red: 1, green: 0.75, blue: 0.35), style: .init(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90)).frame(width: 130, height: 130).opacity(hold > 0 ? 1 : 0)
            }
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in if !holding { startHold() } }
                .onEnded { _ in stopHold() })
            Text(holding ? "Keep holding…" : "Touch and hold the ember")
                .font(.ui(15, .semibold)).foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text("Private test · for adults 18+").font(.caption2).foregroundStyle(.white.opacity(0.3))
        }
        .padding()
        .onAppear { if CommandLine.arguments.contains("-autohatch") { autoHatch() } }
    }

    private func startHold() {
        holding = true
        holdTask = Task { @MainActor in
            let gen = UIImpactFeedbackGenerator(style: .soft)
            while hold < 1 && !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(30))
                hold = min(1, hold + 0.02)
                if Int(hold * 50) % 5 == 0 { gen.impactOccurred(intensity: 0.3 + hold * 0.7) }  // a rising heartbeat
            }
            if hold >= 1 { hatch() }
        }
    }
    private func stopHold() {
        guard hold < 1 else { return }
        holding = false; holdTask?.cancel()
        withAnimation(.easeOut(duration: 0.4)) { hold = 0 }
    }
    private func autoHatch() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5)); startHold()
        }
    }
    private func hatch() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeIn(duration: 0.25)) { flash = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            stage = 1
            withAnimation(.easeOut(duration: 1.4)) { flash = false }
        }
    }

    // MARK: The First Words
    private var wordsPlate: some View {
        VStack {
            Spacer()
            EmberText(text: firstWords[line].text)
                .id(line)
                .padding(.horizontal, 22).padding(.vertical, 18)
                .frame(maxWidth: .infinity, minHeight: 110)
                .background(RoundedRectangle(cornerRadius: 26).fill(Color(red: 0.08, green: 0.05, blue: 0.04).opacity(0.82)))
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(LinearGradient(colors: [Color(red: 1, green: 0.7, blue: 0.3), Color(red: 1, green: 0.45, blue: 0.15)],
                                                                                  startPoint: .leading, endPoint: .trailing), lineWidth: 1.5))
                .shadow(color: Color(red: 1, green: 0.5, blue: 0.1).opacity(0.5), radius: 14)
            HStack {
                Text("\(line + 1) / \(firstWords.count)").font(.caption2).foregroundStyle(.white.opacity(0.4))
                Spacer()
                Button("Skip") { finishWords() }.font(.caption).foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 6)
        }
        .padding(.horizontal, 18).padding(.bottom, 150)
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .onAppear { applyLine() }
        .task { if CommandLine.arguments.contains("-autowords") { for _ in 0..<firstWords.count { try? await Task.sleep(for: .seconds(2.6)); advance() } } }
    }

    private func advance() {
        if line + 1 >= firstWords.count { finishWords(); return }
        line += 1
        applyLine()
    }
    private func applyLine() {
        scene.hero.mouth(0.5)
        director?.mutter()
        if let h = firstWords[line].hush { scene.setVitality(h) }
        if line == 7 { scene.hero.look(at: [0.6, 0.8]) }        // it looks toward the far roads
        if line == 8 { scene.hero.look(at: nil) }
    }
    private func finishWords() {
        scene.setVitality(1)
        withAnimation(.easeInOut(duration: 0.5)) { stage = 3 }
    }

    // MARK: The first question
    private var question: some View {
        VStack(spacing: 10) {
            Spacer()
            EmberText(text: "Before we begin: what would make this year feel truly alive?")
                .padding(18).frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color(red: 0.08, green: 0.05, blue: 0.04).opacity(0.85)))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(red: 1, green: 0.65, blue: 0.3), lineWidth: 1.2))
            ForEach(interests, id: \.self) { i in
                Button { choose(i) } label: {
                    Text(i).font(.ui(15, .semibold))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(Capsule().fill(.black.opacity(0.5)))
                        .overlay(Capsule().stroke(Color(red: 1, green: 0.7, blue: 0.35).opacity(0.6), lineWidth: 1))
                        .foregroundStyle(.white)
                }
            }
            Button { choose("Be closer to people I love") } label: {
                Text("I'm not sure yet").font(.ui(14)).foregroundStyle(.white.opacity(0.7)).padding(6)
            }
        }
        .padding(.horizontal, 22).padding(.bottom, 40)
        .task { if CommandLine.arguments.contains("-autowords") { try? await Task.sleep(for: .seconds(3)); choose(interests[0]) } }
    }

    private func choose(_ i: String) {
        model.chose(i)
        scene.hero.react(.cheer)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation(.easeInOut(duration: 0.8)) { model.go(.home) }
        }
    }
}

/// Text that appears as glowing ember glyphs and melts into English within half a second (Emberspeak).
struct EmberText: View {
    let text: String
    @State private var melted = false
    var body: some View {
        ZStack {
            Text(scrambled).font(.story(19))
                .foregroundStyle(Color(red: 1, green: 0.6, blue: 0.2))
                .blur(radius: melted ? 6 : 0.5).opacity(melted ? 0 : 1)
            Text(text).font(.story(19))
                .foregroundStyle(Color(red: 1, green: 0.93, blue: 0.8))
                .blur(radius: melted ? 0 : 4).opacity(melted ? 1 : 0)
        }
        .multilineTextAlignment(.center)
        .shadow(color: Color(red: 1, green: 0.55, blue: 0.15).opacity(0.6), radius: 6)
        .onAppear { withAnimation(.easeOut(duration: 0.6).delay(0.25)) { melted = true } }
    }
    /// A stand-in for the Emberspeak glyphs: decorative ember shapes in place of letters (the real glyph font comes later).
    private var scrambled: String {
        let glyphs = Array("ᔑᓭᒲᐵᔕᓯᒪᐳᘛᘚᗢᖭᕦᕲᘉᗩ")
        return String(text.map { $0 == " " ? " " : glyphs[Int($0.asciiValue ?? 7) % glyphs.count] })
    }
}
