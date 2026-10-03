// Home, the cockpit (decision 105): your Flame on the stone circle, today's calls floating by the hearth like the
// UI kit (style anchor), the light flying from a finished call to your Flame, and a clear bar: the World, the Book,
// your Flame. A hint always points to where something new waits.
import SwiftUI
import RealityKit

struct HomeView: View {
    let model: ShellModel
    private var scene: SanctuaryScene { model.sanctuary }
    @State private var meter = FrameMeter()
    @State private var director: AliveDirector?
    @State private var open: Call?
    @State private var strand: (from: CGPoint, t: CGFloat)?
    @State private var toast: String?
    @State private var dragStartPan: SIMD2<Float>?
    @State private var satchelOpen = false
    @State private var bookOpen = CommandLine.arguments.contains("-book")
    @State private var flameOpen = CommandLine.arguments.contains("-flamesheet")
    @State private var fullSize: CGSize = .zero

    /// Where the quests you take wait in the Sanctuary (home painting uv, v up): on the ground around the circle.
    private let questSpots: [SIMD2<Float>] = [[0.30, 0.425], [0.775, 0.44], [0.42, 0.33]]
    private var chosen: [Call] { model.calls.filter { $0.chosen && !$0.done } }
    /// Each quest keeps its spot for the day (finishing one never moves the others).
    private func spotFor(_ call: Call) -> SIMD2<Float> {
        let i = model.calls.filter { $0.chosen }.firstIndex { $0.id == call.id } ?? 0
        return questSpots[i % questSpots.count]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // The Sanctuary itself is drawn by the app's one 3D view, underneath (WorldLayer): this layer only
                // catches touches (tap your Spark, look around).
                Color.clear.contentShape(Rectangle()).ignoresSafeArea()
                    .onTapGesture { director?.tapped() }

                // The quests you took, waiting in the world as small glowing objects (they stay attached to their
                // spot when you look around). Tap one to do it.
                GeometryReader { full in
                    TimelineView(.animation) { _ in
                        ZStack {
                            ForEach(chosen) { call in
                                Button { withAnimation(.sheet) { open = call } } label: { QuestObject(call: call) }
                                    .position(scene.screenPoint(homeUV: spotFor(call), in: full.size))
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
                    let to = scene.screenPoint(homeUV: [0.493, 0.56], in: fullSize)
                    let p = CGPoint(x: s.from.x + (to.x - s.from.x) * s.t, y: s.from.y + (to.y - s.from.y) * s.t - sin(s.t * .pi) * 80)
                    Circle().fill(RadialGradient(colors: [.white, Color(red: 1, green: 0.8, blue: 0.4), .clear], center: .center, startRadius: 1, endRadius: 22))
                        .frame(width: 44, height: 44).position(p).allowsHitTesting(false)
                }

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    if let toast { Text(toast).font(.system(size: 14, design: .serif)).padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(.black.opacity(0.6))).foregroundStyle(.white).transition(.opacity).padding(.bottom, 8) }
                    hint
                    cockpitBar
                }
                .padding(.horizontal, 16)

                if let call = open { card(call, size: geo.size) }
                tourLayer
                if satchelOpen { QuestJournal(model: model, isOpen: $satchelOpen).transition(.move(edge: .bottom).combined(with: .opacity)) }
                if bookOpen { BookView(model: model, isOpen: $bookOpen, openOn: "sanctuary").transition(.move(edge: .bottom).combined(with: .opacity)) }
                if flameOpen { FlameSheet(model: model, isOpen: $flameOpen).transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
            .simultaneousGesture(lookAround(geo.size), including: satchelOpen || bookOpen || flameOpen || open != nil ? .subviews : .all)
        }
        .onAppear { meter.start(); setUpWorld() }
        .onChange(of: model.sanctuaryBuilt) { _, _ in setUpWorld() }
        .onDisappear { meter.stop(); director?.stop() }
    }

    /// Your Spark in your color, the world bright, its little life director; then the other worlds preload.
    private func setUpWorld() {
        guard model.sanctuaryBuilt, director == nil else { return }
        scene.hero.tint = SparkTint.shift(model.emberID)
        scene.flameTarget = 1
        scene.setVitality(1)
        let d = AliveDirector(seed: 5, meter: meter)
        d.attach(scene.hero, tempo: 0.55)
        director = d
        model.preloadLater()
    }

    private func ppm(_ size: CGSize) -> CGFloat { size.height / CGFloat(SanctuaryScene.visibleHeight) * 0.98 }

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
            Text("Sanctuary").font(.system(size: 34, weight: .regular, design: .serif)).foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 6)
            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill").font(.caption)
                Text(model.light == 0 ? "Your day is ready" : "\(model.light) light sent into the world today")
                    .font(.system(size: 13, design: .serif))
            }
            .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.top, 8)
    }

    /// The tour's first stops: the satchel, then the world.
    @ViewBuilder private var tourLayer: some View {
        if model.tour == .satchel || model.tour == .world {
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
        if model.tour != nil {
            EmptyView()
        } else if chosen.isEmpty && model.calls.contains(where: { !$0.done }) {
            Button { withAnimation(.sheet) { satchelOpen = true } } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bag.fill").foregroundStyle(Color(red: 1, green: 0.78, blue: 0.42))
                    Text("Choose today's quests from your satchel").font(.system(size: 14, design: .serif))
                    Image(systemName: "chevron.up").font(.caption)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(Capsule().fill(.black.opacity(0.55)))
                .overlay(Capsule().stroke(Color(red: 1, green: 0.78, blue: 0.42).opacity(0.7), lineWidth: 1))
                .foregroundStyle(.white)
            }
            .padding(.bottom, 10)
        } else if let r = model.newHere.first {
            Button { withAnimation(.screen) { model.go(.map) } } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").foregroundStyle(r.color)
                    Text("Something new waits in \(r.name)").font(.system(size: 14, design: .serif))
                    Image(systemName: "chevron.right").font(.caption)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(Capsule().fill(.black.opacity(0.55)))
                .overlay(Capsule().stroke(r.color.opacity(0.7), lineWidth: 1))
                .foregroundStyle(.white)
            }
            .padding(.bottom, 10)
        }
    }

    private var cockpitBar: some View {
        HStack(spacing: 0) {
            barButton("map.fill", "World", badge: !model.newHere.isEmpty, image: UIImage(named: "icon-world.png") ?? UIImage(named: "icon-world-temp.png")) { withAnimation(.screen) { model.go(.map) } }
            barButton("bag.fill", "Satchel", badge: chosen.isEmpty && model.calls.contains(where: { !$0.done })) {
                withAnimation(.sheet) { satchelOpen = true }
            }
            barButton("book.closed.fill", "Book", badge: model.journey.newPages > 0, image: UIImage(named: "icon-book.png") ?? UIImage(named: "prop-scroll.png")) {
                withAnimation(.sheet) { bookOpen = true }
            }
            barButton("flame.fill", "Your Flame", badge: false, image: UIImage(named: "icon-flame.png") ?? SparkTint.image("spark-keyed.png", ember: model.emberID)) {
                director?.tapped()
                withAnimation(.sheet) { flameOpen = true }
            }
        }
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(red: 0.08, green: 0.06, blue: 0.05).opacity(0.78)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(red: 1, green: 0.7, blue: 0.35).opacity(0.35), lineWidth: 1))
        .padding(.bottom, 4)
    }

    private func barButton(_ symbol: String, _ label: String, badge: Bool, image: UIImage? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    if let image {                                       // painted icons (stand-ins until Codex's)
                        Image(uiImage: image).resizable().scaledToFit().frame(width: 32, height: 28)
                            .shadow(color: .orange.opacity(badge ? 0.8 : 0.3), radius: badge ? 8 : 3)
                    } else if symbol == "bag.fill", let img = UIImage(named: "satchel.png") {
                        Image(uiImage: img).resizable().scaledToFit().frame(width: 34, height: 26)     // Codex's satchel
                            .shadow(color: .orange.opacity(badge ? 0.8 : 0.3), radius: badge ? 8 : 3)
                    } else {
                        Image(systemName: symbol).font(.system(size: 22))
                    }
                    if badge { Circle().fill(Color(red: 1, green: 0.55, blue: 0.2)).frame(width: 10, height: 10).offset(x: 6, y: -3) }
                }
                Text(label).font(.system(size: 12, design: .serif))
            }
            .frame(maxWidth: .infinity).foregroundStyle(Color(red: 1, green: 0.88, blue: 0.7))
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
                Text(call.title).font(.system(size: 26, design: .serif)).foregroundStyle(ink)
                Text(call.detail).font(.system(size: 15, design: .serif)).multilineTextAlignment(.center).foregroundStyle(ink.opacity(0.8))
                Text("\(call.minutes) min · light goes to \(call.realm.name)").font(.system(size: 12, weight: .medium, design: .serif)).foregroundStyle(ink.opacity(0.55))
                Button { finish(call, size: size) } label: {
                    Text("I did it").font(.system(size: 18, weight: .semibold, design: .serif)).frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(Capsule().fill(LinearGradient(colors: [Color(red: 1, green: 0.78, blue: 0.42), Color(red: 0.93, green: 0.55, blue: 0.25)], startPoint: .top, endPoint: .bottom)))
                        .foregroundStyle(Color(red: 0.25, green: 0.12, blue: 0.05))
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(colors: [Color(red: 0.98, green: 0.93, blue: 0.82), Color(red: 0.93, green: 0.85, blue: 0.7)], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(red: 0.75, green: 0.58, blue: 0.3).opacity(0.7), lineWidth: 1.5))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(red: 0.75, green: 0.58, blue: 0.3).opacity(0.3), lineWidth: 1).padding(6))
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 6)
            )
            .padding(.horizontal, 14).padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func finish(_ call: Call, size: CGSize) {
        let from = scene.screenPoint(homeUV: spotFor(call), in: fullSize)
        withAnimation { open = nil }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.sheet) { model.complete(call.id) }
        strand = (from, 0)
        Task { @MainActor in
            for k in 1...36 { try? await Task.sleep(for: .milliseconds(25)); strand = (from, CGFloat(k) / 36) }
            strand = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            director?.actionCompleted(call.realm == .grove ? .heart : call.realm == .library ? .mind : call.realm == .highlands ? .body : .spirit)
        }
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
            Text(call.title).font(.system(size: 14, design: .serif)).foregroundStyle(.white)
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
        VStack(spacing: 2) {
            ZStack {
                Ellipse().fill(RadialGradient(colors: [call.realm.color.opacity(0.7), call.realm.color.opacity(0)], center: .center, startRadius: 2, endRadius: 40))
                    .frame(width: 84, height: 70).scaleEffect(bob ? 1.12 : 0.9)
                Image(uiImage: UIImage(named: "\(call.prop).png") ?? UIImage()).resizable().scaledToFit()
                    .frame(width: 50, height: 52)
                    .shadow(color: call.realm.color.opacity(0.8), radius: bob ? 10 : 5)
            }
            Text(call.title).font(.system(size: 11, weight: .semibold, design: .serif)).foregroundStyle(.white)
                .padding(.horizontal, 7).padding(.vertical, 2).background(Capsule().fill(.black.opacity(0.45)))
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
    private let ink = Color(red: 0.27, green: 0.17, blue: 0.1)
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35).ignoresSafeArea().onTapGesture { close() }
            VStack(spacing: 0) {
                Capsule().fill(ink.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 10)
                HStack(alignment: .firstTextBaseline) {
                    Text("Today's quests").font(.system(size: 26, design: .serif)).foregroundStyle(ink)
                    Spacer()
                    Text("\(model.chosenCount) of \(ShellModel.maxChosen) taken").font(.system(size: 13, design: .serif)).foregroundStyle(ink.opacity(0.7))
                }
                .padding(.horizontal, 22).padding(.top, 10)
                Text("Choose what you'll do today. Each one waits for you in the Sanctuary.")
                    .font(.system(size: 14, design: .serif)).foregroundStyle(ink.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 22).padding(.top, 2).padding(.bottom, 12)
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(model.calls) { call in row(call) }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 12)
                }
                .frame(maxHeight: 430)
                Button { close() } label: {
                    Text(model.chosenCount == 0 ? "Close" : "Into the Sanctuary").font(.system(size: 17, weight: .semibold, design: .serif))
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(Capsule().fill(LinearGradient(colors: [Color(red: 1, green: 0.78, blue: 0.42), Color(red: 0.93, green: 0.55, blue: 0.25)], startPoint: .top, endPoint: .bottom)))
                        .foregroundStyle(Color(red: 0.25, green: 0.12, blue: 0.05))
                }
                .padding(.horizontal, 18).padding(.bottom, 18)
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(colors: [Color(red: 0.98, green: 0.93, blue: 0.82), Color(red: 0.93, green: 0.85, blue: 0.7)], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(red: 0.75, green: 0.58, blue: 0.3).opacity(0.7), lineWidth: 1.5))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color(red: 0.75, green: 0.58, blue: 0.3).opacity(0.3), lineWidth: 1).padding(6))
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 6)
            )
            .padding(.horizontal, 10).padding(.bottom, 8)
        }
    }

    private func row(_ call: Call) -> some View {
        let full = model.chosenCount >= ShellModel.maxChosen && !call.chosen
        return HStack(spacing: 12) {
            Image(uiImage: UIImage(named: "\(call.prop).png") ?? UIImage()).resizable().scaledToFit()
                .frame(width: 34, height: 38).frame(width: 46, height: 46)
                .background(Circle().fill(RadialGradient(colors: [call.realm.color.opacity(0.35), .clear], center: .center, startRadius: 2, endRadius: 24)))
            VStack(alignment: .leading, spacing: 2) {
                Text(call.title).font(.system(size: 17, design: .serif)).foregroundStyle(ink)
                Text(call.detail).font(.system(size: 13, design: .serif)).foregroundStyle(ink.opacity(0.72)).lineLimit(2)
                Text("\(call.minutes) min · light to \(call.realm.name)").font(.system(size: 11, weight: .medium, design: .serif)).foregroundStyle(ink.opacity(0.55))
            }
            Spacer(minLength: 4)
            if call.done {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 22)).foregroundStyle(Color(red: 0.55, green: 0.45, blue: 0.15))
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(duration: 0.35)) { model.toggleChosen(call.id) }
                } label: {
                    Text(call.chosen ? "Taken" : "Take").font(.system(size: 14, weight: .semibold, design: .serif))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(call.chosen ? Color(red: 0.45, green: 0.32, blue: 0.15) : Color.clear))
                        .overlay(Capsule().stroke(Color(red: 0.45, green: 0.32, blue: 0.15), lineWidth: 1.2))
                        .foregroundStyle(call.chosen ? Color(red: 1, green: 0.93, blue: 0.8) : ink)
                }
                .disabled(full).opacity(full ? 0.4 : 1)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(call.chosen ? 0.55 : 0.32)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(call.chosen ? call.realm.color.opacity(0.8) : Color(red: 0.75, green: 0.58, blue: 0.3).opacity(0.35), lineWidth: call.chosen ? 1.5 : 1))
    }

    private func close() {
        let taken = model.calls.filter { $0.chosen }.map(\.title)
        if !taken.isEmpty { model.journey.firstQuests(taken) }          // the Book's page about your first quests
        withAnimation(.sheet) { isOpen = false }
    }
}
