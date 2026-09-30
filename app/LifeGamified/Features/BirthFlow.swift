import SwiftUI
import Domain

/// The birth of your Flame (chapter 08 §A.2): darkness → the myth → touch the ember → stone carved around
/// your fire → dawn → your first Path → your first spark. No account, no questionnaire.
struct BirthFlow: View {
    let model: AppModel
    let haptics: Haptics
    let synth: Synth
    var onFinished: () -> Void

    enum Phase: Equatable { case myth(Int), touch, carving, dawn, choosePath, firstSpark, reveal }
    @State private var phase: Phase

    init(model: AppModel, haptics: Haptics, synth: Synth, startPhase: Phase = .myth(0), onFinished: @escaping () -> Void) {
        self.model = model; self.haptics = haptics; self.synth = synth; self.onFinished = onFinished
        _phase = State(initialValue: startPhase)
    }

    /// Resume where an interrupted birth stopped (Codex code review).
    static func resumePhase(_ model: AppModel) -> Phase {
        if !model.isBorn { return .myth(0) }
        if model.activePaths.isEmpty { return .choosePath }
        return .firstSpark
    }
    @State private var holdStart: Date?
    @State private var holdProgress = 0.0
    @State private var stage = FlameStage()
    @State private var ascentShown = 1.0

    private let holdSeconds = 2.6

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch phase {
            case .myth(let i): mythView(i)
            case .touch: touchView
            case .carving: BirthCarving(duration: 3.0)
            case .dawn: BirthDawn(model: model)
            case .choosePath: choosePathView
            case .firstSpark, .reveal: firstSparkView
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 1.0), value: phase)
        .onAppear {
            if case .myth = phase { synth.play(.wind); advanceMyth(after: 0) }
            if phase == .firstSpark && model.firstSparkDone { onFinished() }
        }
    }

    // MARK: 1. darkness and the myth

    private func mythView(_ i: Int) -> some View {
        VStack(spacing: 40) {
            Spacer()
            ember(size: 10 + CGFloat(i) * 4)
            Text(Catalog.myth[i])
                .font(Theme.ceremonial(24)).foregroundStyle(Theme.text)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
                .id(i).transition(.opacity)
            Spacer()
            Text("Private beta · for adults 18+ · by continuing you accept the beta terms")
                .font(.caption2).foregroundStyle(.white.opacity(0.35)).padding(.bottom, 20)
        }
        .contentShape(Rectangle())
        .onTapGesture { advanceMyth(after: 0, from: i) }
    }

    private func advanceMyth(after delay: Double = 2.6, from i: Int? = nil) {
        let current: Int = { if case .myth(let n) = phase { return n } else { return -1 } }()
        guard current >= 0 else { return }
        if let i, i != current { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay == 0 && i == nil ? 2.4 : delay))
            guard case .myth(let n) = phase, n == current else { return }
            if n + 1 < Catalog.myth.count { phase = .myth(n + 1); advanceMyth() } else { phase = .touch }
        }
    }

    /// A pixel ember (decision 77): concentric pixel squares that breathe.
    private func ember(size: CGFloat) -> some View {
        TimelineView(.animation) { tl in
            let pulse = 1 + 0.15 * sin(tl.date.timeIntervalSinceReferenceDate * 2.2)
            Canvas { ctx, sz in
                let px: CGFloat = 6
                let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
                let radius = size * 1.6 * pulse
                let colors: [Color] = [Color(red: 1, green: 0.95, blue: 0.75), Color(red: 1, green: 0.75, blue: 0.3),
                                       .orange, Color(red: 0.8, green: 0.25, blue: 0.1), Color(red: 0.4, green: 0.08, blue: 0.05)]
                let cells = Int(radius / px) + 2
                for gx in -cells...cells {
                    for gy in -cells...cells {
                        let d = sqrt(Double(gx * gx + gy * gy)) * Double(px) / Double(radius)
                        guard d < 1 else { continue }
                        let col = colors[min(colors.count - 1, Int(d * Double(colors.count)))]
                        ctx.fill(Path(CGRect(x: c.x + CGFloat(gx) * px - px / 2, y: c.y + CGFloat(gy) * px - px / 2, width: px, height: px)),
                                 with: .color(col.opacity(1 - d * 0.5)))
                    }
                }
            }
            .frame(width: size * 5, height: size * 5)
        }
    }

    // MARK: 2. touch the ember

    private var touchView: some View {
        VStack(spacing: 48) {
            Spacer()
            ember(size: 14 + 40 * holdProgress)
                .frame(width: 320, height: 320)
                .contentShape(Circle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { _ in startHold() }
                    .onEnded { _ in cancelHold() })
            Text(holdProgress > 0 ? "Hold…" : "Touch the ember.")
                .font(Theme.ceremonial(22)).foregroundStyle(Theme.text)
            Spacer()
        }
    }

    private func startHold() {
        guard holdStart == nil else { return }
        holdStart = .now
        haptics.birthCharge(seconds: holdSeconds)
        synth.play(.swell)
        Task { @MainActor in
            while let start = holdStart {
                holdProgress = min(1, Date.now.timeIntervalSince(start) / holdSeconds)
                if holdProgress >= 1 { ignite(); break }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }

    private func cancelHold() {
        guard phase == .touch, holdProgress < 1 else { return }
        holdStart = nil
        haptics.stopCharge()
        withAnimation(.easeOut(duration: 0.4)) { holdProgress = 0 }
    }

    private func ignite() {
        holdStart = nil
        haptics.stopCharge()
        haptics.strike(.spirit, full: true)
        synth.play(.birth)
        phase = .carving
        haptics.carve(seconds: 2.6)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.0))
            model.witnessBirth()
            haptics.thrum(.spirit, intensity: 1)
            phase = .dawn
            try? await Task.sleep(for: .seconds(3.6))
            phase = .choosePath
        }
    }

    private func fullBleed(_ name: String, caption: String?) -> some View {
        ZStack(alignment: .bottom) {
            if let img = UIImage(named: name) {
                KenBurns(image: img).ignoresSafeArea().transition(.opacity)
            }
            if let caption {
                Text(caption).font(Theme.ceremonial(20)).foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center).padding(32).padding(.bottom, 40)
                    .shadow(color: .black.opacity(0.6), radius: 8)
            }
        }
    }

    // MARK: 3. your first Path

    private var choosePathView: some View {
        ZStack {
            SanctuaryView(vitality: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your first Path").font(Theme.ceremonial(30)).foregroundStyle(Theme.text)
                    Text("Where does this adventure begin? Choose one. More will come.")
                        .font(.subheadline).foregroundStyle(Theme.textSecondary).padding(.bottom, 8)
                    ForEach(Catalog.paths) { t in
                        Button { model.chooseFirstPath(t); haptics.strike(t.pillar, full: false); phase = .firstSpark } label: {
                            HStack(spacing: 12) {
                                Capsule().fill(t.pillar.color).frame(width: 4)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(t.pillar.name).font(.caption2).foregroundStyle(t.pillar.color)
                                    Text(t.name).font(Theme.ceremonial(18)).foregroundStyle(Theme.text)
                                    Text(t.promise).font(.caption).foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(Rectangle().fill(Color(red: 0.06, green: 0.05, blue: 0.08).opacity(0.75))
                                .overlay(Rectangle().strokeBorder(t.pillar.color.opacity(0.5), lineWidth: 2)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20).padding(.top, 60)
            }
        }
    }

    // MARK: 4. your first spark

    private var firstSparkView: some View {
        ZStack {
            SanctuaryView(vitality: model.state.vitality)
            FlameCharacter(vitality: model.state.vitality, totalDepth: model.state.totalDepth, stage: stage)
            VStack {
                VStack(spacing: 6) {
                    Text(phase == .reveal ? "Ascent" : "One thing, right now.")
                        .font(Theme.ceremonial(phase == .reveal ? 16 : 24)).foregroundStyle(Theme.text)
                    if phase == .reveal {
                        Text(String(format: "×%.3f", ascentShown)).font(Theme.ceremonial(40)).foregroundStyle(Theme.text)
                            .contentTransition(.numericText())
                        Text("You've already begun.").font(Theme.ceremonial(18)).foregroundStyle(Theme.gain)
                    }
                }
                .padding(.top, 70)
                Spacer()
                if phase == .firstSpark, let card = model.cards.first(where: { $0.id == Catalog.firstSparkKey }) {
                    ActionCard(card: card, haptics: haptics, synth: synth) { point, deliberate in
                        guard let outcome = model.complete(card) else { return }
                        stage.launch(from: point, pillar: .spirit, big: true)
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(Theme.flight))
                            stage.flare(seconds: 1.4, strength: 0.8)
                            haptics.thrum(.spirit, intensity: 0.9)
                            synth.play(.land(.spirit))
                            phase = .reveal
                            try? await Task.sleep(for: .seconds(0.5))
                            withAnimation(.easeOut(duration: 1.2)) { ascentShown = model.state.ascent }
                            _ = outcome
                            try? await Task.sleep(for: .seconds(3.2))
                            onFinished()
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 60)
                }
            }
        }
        .coordinateSpace(name: "screen")
    }
}

/// A slow cinematic push-in on a still frame (the carving, the dawn).
private struct KenBurns: View {
    let image: UIImage
    @State private var zoom = 1.0
    var body: some View {
        GeometryReader { geo in
            Image(uiImage: image).resizable().scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(zoom).clipped()
                .onAppear { withAnimation(.easeOut(duration: 5)) { zoom = 1.12 } }
        }
    }
}
