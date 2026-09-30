import SwiftUI
import Domain

/// Today (chapter 05, Codex home design): your Flame at the heart of the Sanctuary, your day around it.
struct TodayView: View {
    let model: AppModel
    let haptics: Haptics
    let synth: Synth
    @State private var stage = FlameStage()
    @State private var gainText: (String, Date)?
    @State private var undoable: (UUID, Date)?
    @State private var showCloseDay = false
    @State private var showDev = false
    @State private var showJourney = false
    @State private var forging = false
    @State private var showSettings = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let s = model.state
        ZStack {
            SanctuaryView(vitality: s.vitality, era: model.era)
            FlameView(vitality: s.vitality, depth: s.depth, recentMix: s.recentMix, stage: stage, era: model.era, shake: forging ? 1 : 0)
            VStack(spacing: 0) {
                header(s)
                JourneyMarker(step: model.journeyStep).padding(.top, 6)
                    .contentShape(Rectangle()).onTapGesture { showJourney = true }
                Spacer()
                cards
                footer
            }
            .padding(.horizontal, 16)
        }
        .coordinateSpace(name: "screen")
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showCloseDay) { CloseDaySheet(model: model).presentationDetents([.medium]) }
        .sheet(isPresented: $showDev) { DevMenu(model: model).presentationDetents([.medium]) }
        .sheet(isPresented: $showJourney) { JourneySheet(model: model).presentationDetents([.large]) }
        .sheet(isPresented: $showSettings) { SettingsSheet(model: model) }
        .overlay { if let step = model.pendingUnlock { UnlockMoment(step: step) { model.witnessUnlock(step); haptics.thrum(.spirit, intensity: 0.8) } } }
        .overlay { if model.forgeReady && model.pendingUnlock == nil { ForgeMoment(forging: $forging, haptics: haptics, synth: synth, stage: stage) { model.witnessForge() } } }
        .onAppear { model.dealTodayIfNeeded(); synth.setAmbience(vitality: model.state.vitality) }
        .onDisappear { synth.stopAmbience() }
        .onChange(of: model.state.vitality) { _, v in synth.setAmbience(vitality: v) }
        .onChange(of: scenePhase) { _, p in if p != .active { synth.stopAmbience() } else { synth.setAmbience(vitality: model.state.vitality) } }
        .task { while !Task.isCancelled { try? await Task.sleep(for: .seconds(30)); model.refreshDay() } }
        .overlay(alignment: .top) {
            if let problem = model.storageProblem {
                Text(problem).font(.footnote).padding(12).frame(maxWidth: .infinity)
                    .background(.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 12)).padding()
            } else if model.inSandbox {
                Text("Simulation: nothing here is saved to your real record").font(.caption2)
                    .padding(6).background(.black.opacity(0.5), in: Capsule()).padding(.top, 2)
            }
        }
        .onChange(of: scenePhase) { _, p in if p == .active { model.dealTodayIfNeeded() } }
    }

    private func header(_ s: DerivedState) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.footnote).foregroundStyle(Theme.textSecondary)
                    .onLongPressGesture(minimumDuration: 1.2) { showDev = true }
                Text("Today").font(Theme.ceremonial(34)).foregroundStyle(Theme.text)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "×%.3f", s.ascent)).font(Theme.ceremonial(28)).foregroundStyle(Theme.text)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.5), value: s.ascent)
                    .accessibilityLabel(String(format: "Ascent times %.3f", s.ascent))
                TimelineView(.periodic(from: .now, by: 0.2)) { tl in
                    let visible = gainText.map { tl.date.timeIntervalSince($0.1) < 2.4 } ?? false
                    Text(gainText?.0 ?? " ").font(Theme.ceremonial(14)).foregroundStyle(Theme.gain)
                        .opacity(visible ? 1 : 0).animation(.easeOut(duration: 0.3), value: visible)
                }
            }
        }
        .padding(.top, 8)
    }

    private var cards: some View {
        VStack(spacing: 8) {
            ForEach(model.cards) { card in
                ActionCard(card: card, haptics: haptics, synth: synth,
                           onSwap: card.isSpark && !card.done && !model.sparkSwapUsed && card.id != Catalog.firstSparkKey
                                ? { model.swapSpark(); haptics.strike(card.pillar, full: false) } : nil) { point, deliberate in
                    complete(card, from: point, deliberate: deliberate)
                }
            }
            if let ritual = model.ritualCard {
                ActionCard(card: ritual, haptics: haptics, synth: synth) { point, deliberate in
                    guard let outcome = model.completeRitual() else { return }
                    land(outcome, card: ritual, from: point)
                }
            }
            if model.sparkUnlocked == false {
                Text("Tomorrow, something new waits for you.")
                    .font(Theme.ceremonial(14)).foregroundStyle(Theme.textSecondary).padding(.top, 4)
            }
        }
        .padding(.bottom, 8)
    }

    private var footer: some View {
        HStack {
            TimelineView(.periodic(from: .now, by: 0.5)) { tl in
                if let (id, at) = undoable, tl.date.timeIntervalSince(at) < 5 {
                    Button("Undo") { model.undo(id); undoable = nil; haptics.strike(.spirit, full: false) }
                        .buttonStyle(.bordered).tint(.white.opacity(0.7))
                }
            }
            Spacer()
            Button { showSettings = true } label: { Image(systemName: "gearshape") }
                .buttonStyle(.bordered).tint(.white.opacity(0.7)).accessibilityLabel("Settings")
            Button { showCloseDay = true } label: {
                Label("Close the day", systemImage: "moon.stars").font(.footnote)
            }
            .buttonStyle(.bordered).tint(.white.opacity(0.7))
        }
        .frame(height: 44)
        .padding(.bottom, 6)
    }

    private func complete(_ card: DayCard, from point: CGPoint, deliberate: Bool) {
        guard let outcome = model.complete(card) else { return }
        land(outcome, card: card, from: point)
    }

    private func land(_ outcome: CompletionOutcome, card: DayCard, from point: CGPoint) {
        undoable = (outcome.entryId, .now)
        stage.launch(from: point, pillar: card.pillar, big: card.isSpark || outcome.comeback)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(Theme.flight))
            if outcome.comeback {
                stage.flare(seconds: 2.6, strength: 1.0)
                haptics.comeback()
                synth.play(.comeback)
                gainText = ("Welcome back", .now)
            } else {
                stage.flare(seconds: card.isSpark ? 1.3 : 0.7, strength: card.isSpark ? 0.9 : 0.6)
                haptics.thrum(card.pillar, intensity: 0.85)
                synth.play(.land(card.pillar))
                gainText = (String(format: "+%.2f%%", outcome.gainPercent), .now)
            }
            if outcome.dayComplete {
                try? await Task.sleep(for: .seconds(0.7))
                stage.flare(seconds: 1.2, strength: 0.8)
                haptics.dayComplete()
                synth.play(.chord)
                gainText = ("Day complete · +1%", .now)
            }
        }
    }
}

/// Press-and-hold card (chapter 06 §A.2). A quick tap works too, with the lighter variant.
struct ActionCard: View {
    let card: DayCard
    let haptics: Haptics
    let synth: Synth
    var onSwap: (() -> Void)? = nil
    var onComplete: (CGPoint, Bool) -> Void
    @State private var pressStart: Date?
    @State private var charge = 0.0

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 12) {
                Capsule().fill(card.pillar.color).frame(width: 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.label).font(.caption2).foregroundStyle(card.pillar.color)
                    Text(card.title).font(Theme.ceremonial(17)).foregroundStyle(Theme.text)
                        .lineLimit(2).minimumScaleFactor(0.85)
                    if !card.detail.isEmpty {
                        Text(card.detail).font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    }
                }
                Spacer()
                if let onSwap {
                    Button(action: onSwap) { Image(systemName: "arrow.triangle.2.circlepath") }
                        .foregroundStyle(Theme.textSecondary).accessibilityLabel("Swap this Spark")
                }
                Image(systemName: card.done ? "flame.fill" : "circle")
                    .foregroundStyle(card.done ? card.pillar.color : .white.opacity(0.4))
            }
            .padding(12)
            .frame(width: geo.size.width, height: geo.size.height)
            .background(
                RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 14).fill(card.pillar.color.opacity(card.done ? 0.16 : 0.25 * charge)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(card.pillar.color.opacity(card.done ? 0.6 : 0.2), lineWidth: 1))
            )
            .scaleEffect(1 - 0.04 * charge)
            .opacity(card.done ? 0.75 : 1)
            .gesture(card.done ? nil : press(in: geo))
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onComplete(CGPoint(x: geo.frame(in: .named("screen")).midX, y: geo.frame(in: .named("screen")).midY), true) }
        }
        .frame(height: 68)
    }

    private func press(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("screen"))
            .onChanged { _ in
                guard pressStart == nil else { return }
                pressStart = .now
                haptics.charge(seconds: Theme.hold)
                synth.play(.swell)
                withAnimation(.linear(duration: Theme.hold)) { charge = 1 }
            }
            .onEnded { value in
                let held = pressStart.map { Date.now.timeIntervalSince($0) } ?? 0
                pressStart = nil
                withAnimation(.easeOut(duration: 0.2)) { charge = 0 }
                let inside = geo.frame(in: .named("screen")).insetBy(dx: -30, dy: -30).contains(value.location)
                guard inside else { haptics.stopCharge(); return }
                haptics.stopCharge()
                haptics.strike(card.pillar, full: held >= Theme.hold)
                synth.play(.strike)
                onComplete(value.location, held >= Theme.hold)
            }
    }
}

/// The First Journey marker (chapter 28 §A.8): steps behind you, the next one veiled.
struct JourneyMarker: View {
    let step: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<Catalog.journey.count, id: \.self) { i in
                Circle().fill(i <= step ? Theme.dawn : .white.opacity(0.25)).frame(width: 5, height: 5)
            }
            Text("\(Catalog.roman[step]) · \(Catalog.journey[step])").font(Theme.ceremonial(12)).foregroundStyle(Theme.textSecondary)
            Text("·  next: ···").font(Theme.ceremonial(12)).foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Journey step \(step + 1) of \(Catalog.journey.count): \(Catalog.journey[step])")
    }
}

/// "Close the day" (chapter 05 §A.2): nothing to fill in, just your day settling into the vessel.
struct CloseDaySheet: View {
    let model: AppModel
    var body: some View {
        let s = model.state
        VStack(spacing: 14) {
            Text("Your day").font(Theme.ceremonial(26))
            Text(String(format: "%.0f%% of your day", s.todayCompletion * 100)).font(.title3)
            Text(String(format: "Ascent ×%.3f → ×%.3f", model.ascentYesterday, s.ascent))
                .font(Theme.ceremonial(17)).foregroundStyle(Theme.gain)
            Text(s.todayCompletion >= 1 ? "A full day. Rest well." :
                 s.todayCompletion > 0 ? "Every spark counts. Rest well." : "Tomorrow is ready when you are.")
                .font(Theme.ceremonial(16)).foregroundStyle(.secondary)
        }
        .padding(24)
        .preferredColorScheme(.dark)
    }
}

/// Hidden developer tools for living with the slice: time travel and reset (long-press the date).
struct DevMenu: View {
    let model: AppModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Form {
            Section("Time travel (testing only)") {
                Button("Next day") { model.devAdvance(days: 1); dismiss() }
                Button("Skip 14 days (away)") { model.devAdvance(days: 14); dismiss() }
                Button("Back to real time") { model.devResetTime(); dismiss() }
            }
            Section {
                Button("Delete everything and start over", role: .destructive) { model.devDeleteEverything(); dismiss() }
            } footer: {
                Text(String(format: "Vitality %.2f · Active days %d · Days since birth %d", model.state.vitality,
                            model.state.activeDays, model.state.daysSinceBirth))
            }
        }
    }
}

/// A new step of the First Journey opens: a ceremonial moment, once (chapter 28 §A.8).
struct UnlockMoment: View {
    let step: Int
    var onContinue: () -> Void
    @State private var shown = false
    var body: some View {
        ZStack {
            Color.black.opacity(shown ? 0.72 : 0).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(Catalog.roman[step]).font(Theme.ceremonial(56)).foregroundStyle(Theme.dawn)
                Text(Catalog.journey[step]).font(Theme.ceremonial(30)).foregroundStyle(Theme.text)
                Text(Catalog.journeyUnlocks[step]).font(Theme.ceremonial(18)).foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 36)
                Button("Continue", action: onContinue).buttonStyle(.bordered).tint(Theme.dawn).padding(.top, 20)
            }
            .opacity(shown ? 1 : 0).scaleEffect(shown ? 1 : 0.94)
        }
        .onAppear { withAnimation(.easeOut(duration: 1.0)) { shown = true } }
    }
}

/// Your journey: the steps behind you, the next one veiled; your Paths; your Chronicle.
struct JourneySheet: View {
    let model: AppModel
    var body: some View {
        NavigationStack {
            List {
                Section("The First Journey") {
                    ForEach(0..<Catalog.journey.count, id: \.self) { i in
                        HStack(spacing: 12) {
                            Text(Catalog.roman[i]).font(Theme.ceremonial(18)).frame(width: 34)
                                .foregroundStyle(i <= model.journeyStep ? Theme.dawn : .secondary)
                            if i <= model.journeyStep {
                                VStack(alignment: .leading) {
                                    Text(Catalog.journey[i]).font(Theme.ceremonial(17))
                                    Text(Catalog.journeyUnlocks[i]).font(.caption).foregroundStyle(.secondary)
                                }
                            } else if i == model.journeyStep + 1 {
                                Text("Veiled. Keep living, and it will open.").font(Theme.ceremonial(15)).foregroundStyle(.secondary)
                            } else {
                                Text("···").foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                if let chronicle = model.chronicle() {
                    Section("The Chronicle") {
                        Text(chronicle).font(Theme.ceremonial(16))
                    }
                }
                Section("Your Paths") {
                    ForEach(model.activePaths, id: \.pathId) { p in
                        if let t = Catalog.path(p.templateId) {
                            VStack(alignment: .leading) {
                                Text(t.name).font(Theme.ceremonial(17))
                                Text("\(p.pillar.name) · \(t.stepTitle)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if model.canAddPath {
                        Menu("Add a Path (starts tomorrow)") {
                            ForEach(model.availablePaths) { t in Button("\(t.pillar.name) · \(t.name)") { model.addPath(t) } }
                        }
                    } else if model.journeyStep < 3 {
                        Text("More Paths open at step IV, The Voice.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Your journey")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

/// The Forge (step VI, chapter 03 §A.4): the stone cracks and falls away, the vessel is forged, the world
/// shifts. A ceremony, not a notification. Happens once, and the Metal Era is owned forever.
struct ForgeMoment: View {
    @Binding var forging: Bool
    let haptics: Haptics
    let synth: Synth
    let stage: FlameStage
    var onForged: () -> Void
    @State private var phase = 0     // 0 intro, 1 cracking, 2 revealed

    var body: some View {
        ZStack {
            Color.black.opacity(phase == 1 ? 0.2 : 0.65).ignoresSafeArea().animation(.easeInOut(duration: 1), value: phase)
            if phase == 1 { Color.white.opacity(0.0).ignoresSafeArea() }
            VStack(spacing: 16) {
                if phase == 0 {
                    Text("Thirty days of living.").font(Theme.ceremonial(22)).foregroundStyle(Theme.textSecondary)
                    Text("Your vessel is ready to change.").font(Theme.ceremonial(26)).foregroundStyle(Theme.text)
                    Button("Hold the Flame") { crack() }.buttonStyle(.bordered).tint(Theme.dawn).padding(.top, 24)
                } else if phase == 2 {
                    Text("VI").font(Theme.ceremonial(56)).foregroundStyle(Theme.dawn)
                    Text("The Forge").font(Theme.ceremonial(32)).foregroundStyle(Theme.text)
                    Text("The stone has cracked. Your vessel is forged. It will never be stone again.")
                        .font(Theme.ceremonial(18)).foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 36)
                    Button("Enter the Metal Era") { onForged(); forging = false }
                        .buttonStyle(.bordered).tint(Theme.dawn).padding(.top, 20)
                }
            }
            .padding(.top, 360)
        }
    }

    private func crack() {
        phase = 1
        forging = true
        haptics.birthCharge(seconds: 2.4)
        synth.play(.swell)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            haptics.carve(seconds: 1.2)
            try? await Task.sleep(for: .seconds(1.2))
            forging = false
            stage.flare(seconds: 3.0, strength: 1.2)
            haptics.comeback()
            synth.play(.birth)
            withAnimation(.easeOut(duration: 1.2)) { phase = 2 }
        }
    }
}
