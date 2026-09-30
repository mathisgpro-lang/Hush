// THROWAWAY feel prototype (M0). Not the app. See README.md.
import SwiftUI

@main
struct FeelPrototypeApp: App {
    @State private var state = FeelState()
    var body: some Scene {
        WindowGroup { ContentView(state: state).preferredColorScheme(.dark) }
    }
}

struct ContentView: View {
    @Bindable var state: FeelState
    @State private var showTune = false

    var body: some View {
        ZStack {
            Sanctuary(vitality: state.vitality)
            FlameView(state: state)
            VStack(spacing: 0) {
                header
                Spacer()
                cards
                debugBar
            }
            .padding(.horizontal, 16)
        }
        .coordinateSpace(name: "screen")
        .sheet(isPresented: $showTune) { TuneSheet(tuning: $state.tuning).presentationDetents([.medium]) }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.footnote).foregroundStyle(.white.opacity(0.8))
                Text("Today").font(.system(size: 34, weight: .regular, design: .serif)).foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "×%.3f", state.ascent))
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.4), value: state.ascent)
                TimelineView(.periodic(from: .now, by: 0.1)) { tl in
                    let visible = state.lastGain.map { tl.date.timeIntervalSince($0.at) < 2.2 } ?? false
                    Text(state.lastGain?.text ?? " ")
                        .font(.system(.footnote, design: .serif))
                        .foregroundStyle(Color(red: 1, green: 0.8, blue: 0.5))
                        .opacity(visible ? 1 : 0)
                        .animation(.easeOut(duration: 0.3), value: visible)
                }
            }
        }
        .padding(.top, 12)
    }

    private var cards: some View {
        VStack(spacing: 8) {
            ForEach(state.actions) { item in
                ActionCard(item: item, state: state)
            }
        }
        .padding(.bottom, 10)
    }

    private var debugBar: some View {
        HStack(spacing: 10) {
            Button("☾ 14 days away") { state.simulateAway() }
            Button("New day") { state.newDay() }
            Button("Tune") { showTune = true }
        }
        .font(.caption)
        .buttonStyle(.bordered)
        .tint(.white.opacity(0.6))
        .padding(.bottom, 8)
    }
}

/// The Stone Era Sanctuary (Codex concept art), breathing with Vitality: calm dusk when low, never dark.
struct Sanctuary: View {
    let vitality: Double
    var body: some View {
        GeometryReader { geo in
            ZStack {
                layer("sanctuary", geo: geo)
                layer("sanctuary-embers", geo: geo).opacity(max(0, min(1, (0.9 - vitality) / 0.6)))
                Color(red: 0.08, green: 0.1, blue: 0.22).opacity(0.25 * (1 - vitality))
                LinearGradient(colors: [.black.opacity(0.35), .clear, .black.opacity(0.55)],
                               startPoint: .top, endPoint: .bottom)
            }
            .animation(.easeInOut(duration: 1.2), value: vitality)
        }
        .ignoresSafeArea()
    }

    /// Scaled up and anchored at the bottom so the empty pedestal sits just above the day cards.
    @ViewBuilder private func layer(_ name: String, geo: GeometryProxy) -> some View {
        if let img = UIImage(named: name) {
            Image(uiImage: img).resizable().scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(1.3, anchor: .bottom)
                .clipped()
        } else {
            Color(red: 0.23, green: 0.18, blue: 0.29)
        }
    }
}

/// Press-and-hold card: charge → release → spark (chapter 06 §A.2). A quick tap works too (lighter).
struct ActionCard: View {
    let item: ActionItem
    let state: FeelState
    @State private var pressStart: Date?
    @State private var charge = 0.0

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 12) {
                Capsule().fill(item.pillar.color).frame(width: 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.isRitual ? "Ritual" : item.isSpark ? "Spark · \(item.pillar.name)" : item.pillar.name)
                        .font(.caption2).foregroundStyle(item.pillar.color)
                    Text(item.title).font(.system(.body, design: .serif)).foregroundStyle(.white)
                        .lineLimit(2).minimumScaleFactor(0.85)
                    Text(item.subtitle).font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: item.done ? "flame.fill" : "circle")
                    .foregroundStyle(item.done ? item.pillar.color : .white.opacity(0.4))
            }
            .padding(12)
            .frame(width: geo.size.width, height: geo.size.height)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .fill(item.pillar.color.opacity(item.done ? 0.18 : 0.25 * charge)))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(item.pillar.color.opacity(item.done ? 0.6 : 0.2), lineWidth: 1))
            )
            .scaleEffect(1 - 0.04 * charge)
            .opacity(item.done ? 0.75 : 1)
            .gesture(item.done ? nil : press(in: geo))
        }
        .frame(height: 64)
    }

    private func press(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("screen"))
            .onChanged { _ in
                guard pressStart == nil else { return }
                pressStart = .now
                state.pressBegan()
                withAnimation(.linear(duration: state.tuning.holdSeconds)) { charge = 1 }
            }
            .onEnded { value in
                let held = pressStart.map { Date.now.timeIntervalSince($0) } ?? 0
                pressStart = nil
                withAnimation(.easeOut(duration: 0.2)) { charge = 0 }
                let inside = geo.frame(in: .named("screen")).insetBy(dx: -30, dy: -30).contains(value.location)
                guard inside else { state.pressCancelled(); return }
                state.complete(item, from: value.location, deliberate: held >= state.tuning.holdSeconds)
            }
    }
}

struct TuneSheet: View {
    @Binding var tuning: Tuning
    var body: some View {
        Form {
            Section("Tracking moment") {
                LabeledContent("Hold to charge", value: String(format: "%.2f s", tuning.holdSeconds))
                Slider(value: $tuning.holdSeconds, in: 0.1...0.6)
                LabeledContent("Spark flight", value: String(format: "%.2f s", tuning.flightSeconds))
                Slider(value: $tuning.flightSeconds, in: 0.3...1.4)
                LabeledContent("Thrum strength", value: String(format: "%.2f", tuning.thrumIntensity))
                Slider(value: $tuning.thrumIntensity, in: 0.2...1.0)
                Toggle("Sound", isOn: $tuning.soundOn)
            }
            Section { Text("Tell Claude the values that feel right. They become the starting values in chapter 06.").font(.footnote) }
        }
    }
}
