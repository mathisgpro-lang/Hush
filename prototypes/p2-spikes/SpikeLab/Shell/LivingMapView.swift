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
    @State private var scene = MapScene()
    @State private var selected: RealmID?
    @State private var dragStart: SIMD2<Float>?
    @State private var pinchStart: Float?
    @State private var diving = false
    @State private var flash: Double = 0
    @State private var ready = false

    var body: some View {
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
                if let r = selected, !diving { card(r).transition(.move(edge: .bottom).combined(with: .opacity)) }
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
            Color.black
            RealityView { content in
                content.camera = .virtual
                let lastOpen = roadIndex(roadOrder.last { model.open.contains($0) } ?? .sanctuary)
                do { try await scene.build(open: model.open, flameAt: model.flameAt, lastOpenRoadIndex: lastOpen) }
                catch { print("MAP BUILD FAILED:", error); return }
                content.add(scene.root)
                scene.updates = content.subscribe(to: SceneEvents.Update.self) { e in scene.update(dt: Float(e.deltaTime)) }
                withAnimation(.easeOut(duration: 0.6)) { ready = true }
            }
            .opacity(ready ? 1 : 0)
            .contentShape(Rectangle())
            .simultaneousGesture(moveAround(full))
            .simultaneousGesture(pinch)
            .simultaneousGesture(SpatialTapGesture().onEnded { v in tapped(at: v.location, in: full) })

            // The realms, floating over the map where they are painted (they move with it).
            if ready && !diving {
                TimelineView(.animation) { _ in
                    ZStack {
                        ForEach(roadOrder) { r in
                            marker(r).position(scene.screenPoint(r.mapPoint, in: full))
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
                if dragStart == nil { dragStart = scene.pan }
                let raw = (dragStart ?? .zero) + SIMD2(-Float(v.translation.width), Float(v.translation.height)) / ppm(size)
                let lim = scene.panLimit(zoom: scene.zoom)
                scene.panTarget = SIMD2(rubber(raw.x, lim.x), rubber(raw.y, lim.y))
            }
            .onEnded { v in
                guard !diving else { return }
                let projected = (dragStart ?? .zero) + SIMD2(-Float(v.predictedEndTranslation.width), Float(v.predictedEndTranslation.height)) / ppm(size)
                let lim = scene.panLimit(zoom: scene.zoom)
                scene.panTarget = simd_clamp(projected, -lim, lim)
                dragStart = nil
            }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { v in
                guard !diving else { return }
                if pinchStart == nil { pinchStart = scene.zoom }
                scene.zoomTarget = max(0.92, min(2.4, (pinchStart ?? 1) * Float(v.magnification)))
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

    /// A realm's label, floating over it (visual only: taps on the map pick the nearest realm).
    private func marker(_ r: RealmID) -> some View {
        let isOpen = model.open.contains(r), isNew = model.newHere.contains(r), isSelected = selected == r
        return VStack(spacing: 3) {
            Text(r.name).font(.system(size: isSelected ? 14 : 12, weight: .semibold, design: .serif))
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Capsule().fill(.black.opacity(isSelected ? 0.7 : 0.45)))
                .overlay(Capsule().stroke((isOpen ? r.color : .white).opacity(isSelected ? 0.9 : 0.35), lineWidth: 1))
                .foregroundStyle(.white.opacity(isOpen ? 1 : 0.75))
            if isNew {
                Text("Something new").font(.system(size: 10, weight: .semibold, design: .serif))
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
            if selected != nil { withAnimation(.spring(duration: 0.4)) { selected = nil } }
            return
        }
        let r = best.0
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(duration: 0.45)) { selected = r }
        // Glide so the realm sits above its card.
        scene.panTarget = scene.centerPan(on: CGPoint(x: r.mapPoint.x, y: r.mapPoint.y + 160), zoom: scene.zoom)
    }

    private func card(_ r: RealmID) -> some View {
        let isOpen = model.open.contains(r)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: isOpen ? r.symbol : "lock.fill").font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isOpen ? r.color : .white.opacity(0.6))
                    .frame(width: 34, height: 34).background(Circle().fill(.white.opacity(0.08)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.name).font(.system(size: 20, design: .serif)).foregroundStyle(.white)
                    Text(r.pillar).font(.system(size: 12, weight: .medium, design: .serif)).foregroundStyle(r.color)
                }
                Spacer()
                Button { withAnimation(.spring(duration: 0.4)) { selected = nil } } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white.opacity(0.7))
                        .frame(width: 30, height: 30).background(Circle().fill(.white.opacity(0.08)))
                }
            }
            Text(r.lore).font(.system(size: 15, design: .serif)).foregroundStyle(.white.opacity(0.85)).fixedSize(horizontal: false, vertical: true)
            if isOpen {
                Button { enter(r) } label: {
                    Text(r == .sanctuary ? "Fly home" : "Fly there").font(.system(size: 17, weight: .semibold, design: .serif))
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(Capsule().fill(LinearGradient(colors: [Color(red: 1, green: 0.78, blue: 0.42), Color(red: 0.95, green: 0.55, blue: 0.25)], startPoint: .top, endPoint: .bottom)))
                        .foregroundStyle(Color(red: 0.25, green: 0.12, blue: 0.05))
                }
            } else {
                Label("Still in the Hush. It wakes with \(r.opensWhen).", systemImage: "moon.zzz.fill")
                    .font(.system(size: 14, design: .serif)).foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color(red: 0.09, green: 0.07, blue: 0.1).opacity(0.92)))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(r.color.opacity(0.45), lineWidth: 1))
        .padding(.bottom, 24)
    }

    private var header: some View {
        HStack {
            Button { withAnimation(.easeInOut(duration: 0.6)) { model.go(.home) } } label: {
                Label("Home", systemImage: "house.fill").font(.system(size: 15, design: .serif))
                    .padding(.horizontal, 14).padding(.vertical, 9).background(Capsule().fill(.black.opacity(0.55))).foregroundStyle(.white)
            }
            Spacer()
            Text("The Emberlands").font(.system(size: 20, design: .serif)).foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 8).background(Capsule().fill(.black.opacity(0.45)))
        }
        .padding(.top, 4)
    }

    /// The bird's dive: the camera lifts, swoops down through the clouds onto the realm, its light fills the
    /// screen, and the realm opens around you.
    private func enter(_ r: RealmID) {
        guard !diving else { return }
        withAnimation(.easeOut(duration: 0.3)) { diving = true }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        scene.startDive(to: r.mapPoint)
        model.arrivingByDive = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.easeIn(duration: 0.55)) { flash = 1 }
            try? await Task.sleep(for: .milliseconds(560))
            model.go(r == .sanctuary ? .home : .realm(r))
        }
    }
}
