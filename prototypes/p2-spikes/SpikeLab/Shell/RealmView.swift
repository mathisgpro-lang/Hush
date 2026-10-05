// Inside a world (decision 105): the Whispering Grove with your Flame on the stone circle, glowing spots to explore
// (tap: the camera glides there and the spot tells its story), a clear way back to the map. The Grove restores from
// your Heart light (S3).
import SwiftUI
import RealityKit

struct Spot: Identifiable {
    let id: String, title: String, line: String, symbol: String
    let uv: SIMD2<Float>            // in the painting (v up)
    var action: String? = nil
}

let groveSpots: [Spot] = [
    Spot(id: "circle", title: "The Gathering", line: "Every week, lights gather here. This week's Gathering: tell someone why you're grateful for them.", symbol: "circle.hexagongrid.fill", uv: [0.36, 0.3], action: "Join this week's Gathering"),
    Spot(id: "tree", title: "Your Journey", line: "Lanterns for the Ones You Love. Each kind word relights a lantern in these old trees.", symbol: "lamp.desk.fill", uv: [0.2, 0.6], action: "Send a lantern (a real Heart action)"),
    Spot(id: "twins", title: "Nim & Ro", line: "\"You came back!\" \"We knew you would.\" The twins keep the Grove's counsel, with sources, never lectures.", symbol: "sparkles", uv: [0.78, 0.47]),
    Spot(id: "pool", title: "The quiet pool", line: "The water remembers every lantern you've lit. It moves again as the Grove wakes.", symbol: "drop.fill", uv: [0.62, 0.21]),
]

struct RealmView: View {
    let model: ShellModel
    let realm: RealmID
    private var scene: RealmScene { model.realmScene(realm) }
    private var spots: [Spot] { RealmContent.spots(realm) }
    private var built: Bool { model.realmsBuilt.contains(realm) }
    @State private var meter = FrameMeter()
    @State private var director: AliveDirector?
    @State private var focused: Spot?
    @State private var ready = false
    @State private var appear = false
    @State private var dragStart: SIMD2<Float>?
    @State private var bookOpen = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // The Grove is drawn by the app's one 3D view underneath; this layer catches touches.
                Color.clear.contentShape(Rectangle()).ignoresSafeArea()
                    .onTapGesture { if focused == nil { director?.tapped() } else { unfocus() } }

                // The spots to explore, attached to their place in the Grove (they move with it as you look around).
                if ready && focused == nil {
                    GeometryReader { full in
                        TimelineView(.animation(minimumInterval: nil, paused: model.overlayOpen)) { _ in
                            ZStack {
                                ForEach(spots) { s in
                                    Button { focus(s) } label: { SpotMarker(spot: s) }
                                        .position(scene.screenPoint(s.uv.x, s.uv.y, in: full.size))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .frame(width: full.size.width, height: full.size.height)
                        }
                    }
                    .ignoresSafeArea()
                }

                VStack {
                    header
                    Spacer()
                    if model.tour == .grove && ready {
                        TourBubble(text: "The Whispering Grove. Every kind word you send relights one of its lanterns. Come, let's go home and begin.",
                                   button: "Home", next: {
                                       model.tour = nil
                                       withAnimation(.screen) { model.go(.home) }
                                   }, skip: { withAnimation { model.tour = nil } })
                        .padding(.bottom, 24)
                    } else if let s = focused { spotCard(s) } else if ready { footer }
                }
                .padding(.horizontal, 16)
            }
            .overlay { if bookOpen { BookView(model: model, isOpen: $bookOpen, openOn: realm.rawValue).transition(.move(edge: .bottom)) } }
            .simultaneousGesture(lookAround(geo.size), including: bookOpen ? .subviews : .all)     // the whole screen: drags anywhere look around
        }
        .onAppear { meter.start(); setUpWorld() }
        .onChange(of: bookOpen) { _, covered in model.overlayOpen = covered }
        .onChange(of: built) { _, _ in setUpWorld() }
        .onDisappear { meter.stop(); director?.stop(); model.overlayOpen = false }
    }

    private func setUpWorld() {
        guard built, director == nil else { return }
        scene.hero.tint = SparkTint.shift(model.emberID)       // your ember's color
        // How awake the realm is comes from your real actions in its pillar (each one relights a few of its lights).
        let lit = Float(model.journey.light(for: realm)) * 3
        scene.heartDepth = max(scene.heartDepth, realm == .grove ? max(6, lit) : lit)   // (prototype: the Grove starts a little awake)
        let d = AliveDirector(seed: 9, meter: meter)
        d.attach(scene.hero, tempo: 0.55)
        director = d
        withAnimation(.easeOut(duration: 0.25)) { ready = true }
    }

    /// Drag to look around the Grove (Clash of Clans: a little in every direction, rubber-band edges, a glide).
    private func lookAround(_ size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { v in
                guard focused == nil else { return }
                if dragStart == nil { dragStart = scene.pan; scene.fingerDown = true }
                let ppm = Float(size.height) / (2 * RealmScene.distance * tan(RealmScene.fov / 2 * .pi / 180))
                let raw = (dragStart ?? .zero) + SIMD2(-Float(v.translation.width), Float(v.translation.height)) / ppm
                scene.panTarget = SIMD2(EdgeSafety.rubberBand(raw.x, scene.panLimit.x), EdgeSafety.rubberBand(raw.y, scene.panLimit.y))
            }
            .onEnded { v in
                guard focused == nil else { return }
                let ppm = Float(size.height) / (2 * RealmScene.distance * tan(RealmScene.fov / 2 * .pi / 180))
                let projected = (dragStart ?? .zero) + SIMD2(-Float(v.predictedEndTranslation.width), Float(v.predictedEndTranslation.height)) / ppm
                scene.panTarget = simd_clamp(projected, -scene.panLimit, scene.panLimit)
                dragStart = nil; scene.fingerDown = false
            }
    }
    private func rubber(_ x: Float, _ lim: Float) -> Float {
        let over = abs(x) - lim
        guard over > 0 else { return x }
        let k: Float = 0.05
        return (lim + k * (1 - exp(-over / k))) * (x < 0 ? -1 : 1)
    }

    private var header: some View {
        HStack(alignment: .top) {
            Button { back() } label: {
                Label("Map", systemImage: "map.fill").font(.ui(15))
                    .padding(.horizontal, 14).padding(.vertical, 9).background(Capsule().fill(.black.opacity(0.55))).foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(realm.name).font(.story(20)).foregroundStyle(.white)
                let level = Restoration.level(depth: scene.heartDepth)
                Text("\(realm.pillar) · \(Restoration.names[level]) · \(scene.litCount) \(RealmContent.lights(realm)) lit")
                    .font(.ui(12)).foregroundStyle(realm.color)
            }
            .padding(.horizontal, 14).padding(.vertical, 8).background(RoundedRectangle(cornerRadius: 16).fill(.black.opacity(0.5)))
        }
        .padding(.top, 4)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Text("Tap a glowing spot to explore")
                .font(.ui(14)).foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 16).padding(.vertical, 9).background(Capsule().fill(.black.opacity(0.5)))
            // The Book, open on this world's chapter (decision 129).
            Button { withAnimation(.sheet) { bookOpen = true } } label: {
                Image(uiImage: UIImage(named: "icon-book.png") ?? UIImage(named: "prop-scroll.png") ?? UIImage()).resizable().scaledToFit()
                    .frame(width: 30, height: 26).padding(8).background(Circle().fill(.black.opacity(0.5)))
                    .overlay(alignment: .topTrailing) {
                        if model.journey.newPages > 0 { Circle().fill(Color(red: 1, green: 0.55, blue: 0.2)).frame(width: 10, height: 10) }
                    }
            }
        }
        .padding(.bottom, 30)
    }

    private func spotCard(_ s: Spot) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: s.symbol).foregroundStyle(realm.color)
                Text(s.title).font(.story(22))
                Spacer()
                Button { unfocus() } label: { Image(systemName: "xmark.circle").font(.title2) }
            }
            Text(s.line).font(.ui(15)).foregroundStyle(.white.opacity(0.85)).frame(maxWidth: .infinity, alignment: .leading)
            if let a = s.action {
                Button {
                    scene.act()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    unfocus()
                } label: {
                    Text(a).font(.ui(16)).frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(Capsule().fill(realm.color.opacity(0.35))).overlay(Capsule().stroke(realm.color, lineWidth: 1))
                }
            }
        }
        .foregroundStyle(.white).padding(18)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(red: 0.07, green: 0.06, blue: 0.08).opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(realm.color.opacity(0.5), lineWidth: 1))
        .padding(.bottom, 24)
        .transition(.move(edge: .bottom))
    }

    private func focus(_ s: Spot) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        scene.panTarget = .zero                      // the spot's close-up is framed from the home view
        scene.focus = scene.spot(s.uv.x, s.uv.y)
        scene.hero.look(at: [s.uv.x < 0.5 ? -0.7 : 0.7, s.uv.y > 0.36 ? 0.5 : -0.3])
        withAnimation(.sheet) { focused = s }
    }

    private func unfocus() {
        scene.focus = nil
        scene.hero.look(at: nil)
        withAnimation(.sheet) { focused = nil }
    }

    private func back() {
        unfocus()
        withAnimation(.easeIn(duration: 0.4)) { appear = false }
        withAnimation(.screen) { model.go(.map) }
    }
}

/// A glowing, gently pulsing spot to explore.
struct SpotMarker: View {
    let spot: Spot
    @State private var pulse = false
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().fill(Color(red: 1, green: 0.85, blue: 0.5).opacity(0.25)).frame(width: pulse ? 46 : 34)
                Circle().fill(Color(red: 1, green: 0.85, blue: 0.55)).frame(width: 14).shadow(color: .orange, radius: 8)
            }
            .frame(width: 48, height: 48)
            Text(spot.title).font(.ui(12, .bold))
                .padding(.horizontal, 8).padding(.vertical, 3).background(Capsule().fill(.black.opacity(0.55))).foregroundStyle(.white)
        }
        .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}
