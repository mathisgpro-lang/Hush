// The world map screen (iteration 2, decision 124): the living map (MapScene) you move around like a Clash of Clans
// map (drag, pinch, soft edges), realms you can tap to learn about, and the bird's dive into a realm: the camera
// lifts, then swoops down through the clouds onto it, and the realm opens around you.
import SwiftUI
import RealityKit

extension RealmID {
    /// One line about each realm, for its card on the map.
    var lore: String {
        switch self {
        case .sanctuary: "Home. Your Flame's stone circle, where every day begins."
        case .grove: "Ancient trees full of lanterns, each one lit by a kind word. The realm of the Heart."
        case .stillwater: "A silent lake that mirrors the sky. The realm of the Spirit: calm, breath, reflection."
        case .highlands: "Cliffs and trails above the clouds. The realm of the Body."
        case .library: "Floating islands of books and lamplight. The realm of the Mind."
        case .wilds: "Forests and rivers you help to thrive. The realm of the World around you."
        case .forge: "A mountain of fire and anvils, where skills are hammered into shape. The realm of Craft."
        case .veil: "No one knows what lies beyond. Not yet."
        }
    }
}

struct LivingMapView: View {
    let model: ShellModel
    private var scene: MapScene { model.mapScene }
    @State private var selected: RealmID?
    @State private var dragStart: SIMD2<Float>?
    @State private var pinchStart: Float?
    @State private var diving = false
    @State private var flash: Double = 0
    @State private var ready = false

    var body: some View {
        let _ = PerfProbe.body("Map")
        // The map fills the whole screen (one coordinate space for the map, its labels and taps); the header and the
        // realm's card sit on top of it, inside the safe area.
        GeometryReader { geo in
            mapLayer(geo.size)
        }
        .ignoresSafeArea()
        .overlay {
            VStack {
                header
                Spacer()
                if model.tour == .map && !diving {
                    TourBubble(text: "The Emberlands. Each realm wakes as you grow in its part of life. Our first journey is the Whispering Grove.",
                               button: "Fly there", next: {
                                   model.tour = .grove
                                   withAnimation(.sheet) { selected = .grove }
                                   enter(.grove)
                               }, skip: { withAnimation { model.tour = nil } })
                    .padding(.bottom, 24)
                } else if let r = selected, !diving { card(r).transition(.move(edge: .bottom)) }
            }
            .padding(.horizontal, 16)
        }
        .overlay {
            // The end of the dive: the realm's light fills the screen, then the realm opens.
            ZStack {
                Color(selected?.color ?? .white).opacity(flash).blendMode(.screen)
                Color.white.opacity(flash * 0.6)
            }
            .ignoresSafeArea().allowsHitTesting(false)
        }
    }

    private func mapLayer(_ full: CGSize) -> some View {
        ZStack {
            Color.clear                                  // the map is drawn by the app's one 3D view underneath
            .contentShape(Rectangle())
            .simultaneousGesture(moveAround(full))
            .simultaneousGesture(pinch)
            .simultaneousGesture(SpatialTapGesture().onEnded { v in tapped(at: v.location, in: full) })

            // The realms, floating over the map where they are painted (they move with it).
            if model.mapBuilt && !diving {
                TimelineView(.animation) { _ in
                    ZStack {
                        ForEach(roadOrder) { r in
                            let p = scene.screenPoint(r.mapPoint, in: full)
                            marker(r).position(inside(p, full)).opacity(p.y < 170 ? max(0, Double(p.y - 120) / 50) : 1)   // fades under the header
                        }
                    }
                    .frame(width: full.width, height: full.height)
                }
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: Moving around (Clash of Clans): drag to move, pinch to zoom, soft edges.

    private func ppm(_ size: CGSize) -> Float {
        let visibleH = 2 * (MapScene.distance / scene.zoom) * tan(MapScene.fov / 2 * .pi / 180)
        return Float(size.height) / visibleH
    }

    private func moveAround(_ size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { v in
                guard !diving else { return }
                if dragStart == nil { dragStart = scene.pan; scene.fingerDown = true }
                let raw = (dragStart ?? .zero) + SIMD2(-Float(v.translation.width), Float(v.translation.height)) / ppm(size)
                let lim = scene.panLimit(zoom: scene.zoom)
                scene.panTarget = SIMD2(EdgeSafety.rubberBand(raw.x, lim.x), EdgeSafety.rubberBand(raw.y, lim.y))
            }
            .onEnded { v in
                guard !diving else { return }
                let projected = (dragStart ?? .zero) + SIMD2(-Float(v.predictedEndTranslation.width), Float(v.predictedEndTranslation.height)) / ppm(size)
                let lim = scene.panLimit(zoom: scene.zoom)
                scene.panTarget = simd_clamp(projected, -lim, lim)
                dragStart = nil; scene.fingerDown = false
            }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { v in
                guard !diving else { return }
                if pinchStart == nil { pinchStart = scene.zoom }
                scene.zoomTarget = max(1, min(2.4, (pinchStart ?? 1) * Float(v.magnification)))      // never wider than the map
            }
            .onEnded { _ in
                scene.zoomTarget = max(1, min(2.2, scene.zoomTarget))         // settles back inside the limits
                let lim = scene.panLimit(zoom: scene.zoomTarget)
                scene.panTarget = simd_clamp(scene.panTarget, -lim, lim)
                pinchStart = nil
            }
    }

    private func rubber(_ x: Float, _ lim: Float) -> Float {
        let over = abs(x) - lim
        guard over > 0 else { return x }
        let k: Float = 0.06
        return (lim + k * (1 - exp(-over / k))) * (x < 0 ? -1 : 1)
    }

    // MARK: Realms

    /// A label near the screen's side slides in to stay whole (never cut off); far off screen it leaves with its realm.
    private func inside(_ p: CGPoint, _ size: CGSize) -> CGPoint {
        guard p.x > -30, p.x < size.width + 30 else { return p }
        return CGPoint(x: min(max(p.x, 92), size.width - 92), y: p.y)
    }

    /// A realm's label, floating over it (visual only: taps on the map pick the nearest realm).
    private func marker(_ r: RealmID) -> some View {
        let isOpen = model.open.contains(r), isNew = model.newHere.contains(r), isSelected = selected == r
        return VStack(spacing: 3) {
            Text(r.name).font(.ui(isSelected ? 14 : 12, .bold))
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Capsule().fill(.black.opacity(isSelected ? 0.7 : 0.45)))
                .overlay(Capsule().stroke((isOpen ? r.color : .white).opacity(isSelected ? 0.9 : 0.35), lineWidth: 1))
                .foregroundStyle(.white.opacity(isOpen ? 1 : 0.75))
            if isNew {
                Text("Something new").font(.ui(10, .bold))
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Capsule().fill(Color(red: 1, green: 0.55, blue: 0.25).opacity(0.9))).foregroundStyle(.white)
            }
        }
        .offset(y: -34)
    }

    /// A tap on the map: the nearest realm (its painted place or its label) within reach is selected.
    private func tapped(at p: CGPoint, in size: CGSize) {
        guard !diving else { return }
        let hits = roadOrder.map { r -> (RealmID, CGFloat) in
            let c = scene.screenPoint(r.mapPoint, in: size)
            let dl = hypot(p.x - c.x, p.y - (c.y - 34))             // the label
            let dp = hypot(p.x - c.x, p.y - c.y)                    // the place itself
            return (r, min(dl, dp))
        }
        guard let best = hits.min(by: { $0.1 < $1.1 }), best.1 < 90 else {
            if selected != nil { withAnimation(.sheet) { selected = nil } }
            return
        }
        let r = best.0
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.sheet) { selected = r }
        if model.open.contains(r) && r != .sanctuary { Task { await model.ensure(.realm(r)) } }   // ready before you fly
        // Glide so the realm sits above its card.
        scene.panTarget = scene.centerPan(on: CGPoint(x: r.mapPoint.x, y: r.mapPoint.y + 160), zoom: scene.zoom)
    }

    private func card(_ r: RealmID) -> some View {
        let isOpen = model.open.contains(r), ink = Theme.ink
        let canBuy = ShellModel.builtRealms.contains(r) && r != .veil
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: isOpen ? r.symbol : "lock.fill").font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isOpen ? r.color : ink.opacity(0.5))
                    .frame(width: 38, height: 38).background(Circle().fill(Theme.night.opacity(0.85)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.name).font(.story(21)).foregroundStyle(ink)
                    Text(r.pillar).font(.ui(12, .bold)).foregroundStyle(Theme.accent)
                }
                Spacer()
                Button { withAnimation(.sheet) { selected = nil } } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(ink.opacity(0.6))
                        .frame(width: 30, height: 30).background(Circle().fill(ink.opacity(0.08)))
                }
            }
            Text(r.lore).font(.ui(15)).foregroundStyle(ink.opacity(0.85)).fixedSize(horizontal: false, vertical: true)
            if isOpen {
                Button { enter(r) } label: { goldLabel(r == .sanctuary ? "Fly home" : "Fly there") }
            } else if canBuy {
                // Decision 136: Embers earned by living open the next world (never bought with money).
                let have = model.journey.embers
                Button {
                    if model.journey.buy(r) {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        model.newHere.insert(r); model.mapScene.refresh(open: model.open)      // the realm wakes on the map
                    }
                } label: { goldLabel("Open it · \(r.price) Embers").opacity(have >= r.price ? 1 : 0.45) }
                .disabled(have < r.price)
                Text(have >= r.price ? "You have \(have) Embers, all earned by living." : "You have \(have) of \(r.price) Embers. Every quest, every day kept adds more.")
                    .font(.ui(12)).foregroundStyle(ink.opacity(0.6))
            } else {
                Label("Still in the Hush. It wakes with \(r.opensWhen).", systemImage: "moon.zzz.fill")
                    .font(.ui(14)).foregroundStyle(ink.opacity(0.7))
            }
        }
        .padding(20)
        .background(SheetPaper(corner: 24))
        .padding(.bottom, 24)
    }

    private func goldLabel(_ t: String) -> some View {
        Text(t).font(.ui(17, .bold))
            .frame(maxWidth: .infinity).padding(.vertical, 13)
            .background(Capsule().fill(LinearGradient(colors: [Theme.gold, Color(red: 0.95, green: 0.55, blue: 0.25)], startPoint: .top, endPoint: .bottom)))
            .foregroundStyle(Color(red: 0.25, green: 0.12, blue: 0.05))
    }

    private var header: some View {
        HStack {
            Button { withAnimation(.screen) { model.go(.home) } } label: {
                Label("Home", systemImage: "house.fill").font(.ui(15))
                    .padding(.horizontal, 14).padding(.vertical, 9).background(Capsule().fill(.black.opacity(0.55))).foregroundStyle(.white)
            }
            Spacer()
            Text("The Emberlands").font(.story(20)).foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 8).background(Capsule().fill(.black.opacity(0.45)))
            Spacer()
            // Your Embers (decision 136): what living has earned you.
            HStack(spacing: 5) {
                Image(systemName: "sparkle").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.gold)
                Text("\(model.journey.embers)").font(.num(15, .bold))
            }
            .foregroundStyle(.white).padding(.horizontal, 12).padding(.vertical, 8).background(Capsule().fill(.black.opacity(0.55)))
        }
        .padding(.top, 4)
    }

    /// The bird's dive: the camera lifts, swoops down through the clouds onto the realm, its light fills the
    /// screen, and the realm opens around you.
    private func enter(_ r: RealmID) {
        guard !diving else { return }
        if r != .sanctuary && !model.realmsBuilt.contains(r) {         // still preparing: fly the moment it's ready
            Task { @MainActor in await model.ensure(.realm(r)); enter(r) }
            return
        }
        withAnimation(.easeOut(duration: 0.2)) { diving = true }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        scene.startDive(to: r.mapPoint)
        model.arrivingByDive = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(820))           // the swoop itself, seen (quick, like a game)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.easeIn(duration: 0.28)) { flash = 1 }     // the realm's light takes over at the very end
            try? await Task.sleep(for: .milliseconds(290))
            model.go(r == .sanctuary ? .home : .realm(r))
        }
    }
}
