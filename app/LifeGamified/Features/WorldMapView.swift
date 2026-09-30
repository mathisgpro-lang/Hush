import SwiftUI
import Domain

/// The world map v1 (chapter 29 §A.3, U4): places open only by living; tap to travel; enter to discover.
/// Drawn islands and paths are placeholders until the illustrated map (U3) arrives.
struct WorldMapView: View {
    let model: AppModel
    let haptics: Haptics
    @Environment(\.dismiss) private var dismiss
    @State private var here = UserDefaults.standard.string(forKey: "world.here") ?? "sanctuary"
    @State private var travel: (from: CGPoint, to: CGPoint, start: Date)?
    @State private var entering: Place?
    @State private var stage = FlameStage()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color(red: 0.12, green: 0.09, blue: 0.22), Color(red: 0.32, green: 0.18, blue: 0.28),
                                        Color(red: 0.55, green: 0.33, blue: 0.25)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                TimelineView(.animation) { tl in
                    Canvas { ctx, size in drawMap(&ctx, size: size, t: tl.date.timeIntervalSinceReferenceDate) }
                }
                .ignoresSafeArea()
                ForEach(WorldCatalog.places) { place in
                    let open = model.isOpen(place)
                    Button { tap(place, in: geo.size) } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle().fill(open ? place.color : Color.white.opacity(0.08)).frame(width: 58, height: 58)
                                    .shadow(color: open ? place.color.opacity(0.7) : .clear, radius: 12)
                                Image(systemName: open ? place.icon : "questionmark").font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(open ? Color.black.opacity(0.7) : .white.opacity(0.35))
                            }
                            Text(open ? place.name : "···").font(Theme.ceremonial(13)).foregroundStyle(open ? .white : .white.opacity(0.4))
                        }
                    }
                    .buttonStyle(.plain)
                    .position(x: place.at.x * geo.size.width, y: place.at.y * geo.size.height)
                    .accessibilityLabel(open ? place.name : "A veiled place")
                }
                // Your Flame on the map.
                TimelineView(.animation) { tl in
                    let pos = flamePosition(in: geo.size, now: tl.date)
                    FlameCharacter(vitality: max(0.5, model.state.vitality), totalDepth: model.state.totalDepth, stage: stage,
                                   era: model.era, center: pos.y / geo.size.height - 0.085, height: 0.08)
                        .offset(x: pos.x - geo.size.width / 2)
                }
                .allowsHitTesting(false)
                VStack {
                    HStack {
                        Text("The World").font(Theme.ceremonial(28)).foregroundStyle(.white)
                        Spacer()
                        Button("Done") { dismiss() }.buttonStyle(.bordered).tint(.white.opacity(0.7))
                    }
                    .padding()
                    Spacer()
                }
            }
        }
        .sheet(item: $entering) { place in LocationScene(place: place, model: model) }
        .preferredColorScheme(.dark)
    }

    private func point(_ id: String, _ size: CGSize) -> CGPoint {
        let p = WorldCatalog.place(id)?.at ?? CGPoint(x: 0.5, y: 0.8)
        return CGPoint(x: p.x * size.width, y: p.y * size.height)
    }

    private func flamePosition(in size: CGSize, now: Date) -> CGPoint {
        guard let t = travel else { return point(here, size) }
        let p = min(1, now.timeIntervalSince(t.start) / 1.4)
        let e = p < 0.5 ? 2 * p * p : 1 - pow(-2 * p + 2, 2) / 2
        let hop = sin(p * .pi * 6) * 6
        return CGPoint(x: t.from.x + (t.to.x - t.from.x) * e, y: t.from.y + (t.to.y - t.from.y) * e - abs(hop))
    }

    private func tap(_ place: Place, in size: CGSize) {
        guard model.isOpen(place) else { haptics.strike(.spirit, full: false); return }
        if place.id == here { entering = place; model.visit(place); return }
        haptics.charge(seconds: 0.2)
        travel = (point(here, size), point(place.id, size), .now)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.45))
            here = place.id
            UserDefaults.standard.set(place.id, forKey: "world.here")
            travel = nil
            haptics.thrum(.world, intensity: 0.7)
            stage.flare(seconds: 0.8, strength: 0.5)
            entering = place
            model.visit(place)
        }
    }

    private func drawMap(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        // Stars.
        for i in 0..<60 {
            let x = Double((i * 73) % 100) / 100 * size.width, y = Double((i * 37) % 45) / 100 * size.height
            let tw = 0.4 + 0.6 * abs(sin(t * 0.8 + Double(i)))
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)), with: .color(.white.opacity(0.5 * tw)))
        }
        // Paths between places (dotted); bright if both ends are open.
        for (a, b) in WorldCatalog.paths {
            guard let pa = WorldCatalog.place(a), let pb = WorldCatalog.place(b) else { continue }
            let open = model.isOpen(pa) && model.isOpen(pb)
            var path = Path()
            path.move(to: CGPoint(x: pa.at.x * size.width, y: pa.at.y * size.height))
            path.addLine(to: CGPoint(x: pb.at.x * size.width, y: pb.at.y * size.height))
            ctx.stroke(path, with: .color(.white.opacity(open ? 0.55 : 0.12)), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 10]))
        }
        // Mist over veiled places (never see the whole map, P16).
        for place in WorldCatalog.places where !model.isOpen(place) {
            let c = CGPoint(x: place.at.x * size.width, y: place.at.y * size.height)
            for k in 0..<4 {
                let r = 44.0 + Double(k) * 10 + sin(t * 0.6 + Double(k)) * 6
                let dx = sin(t * 0.3 + Double(k) * 1.7) * 14
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r + dx, y: c.y - r * 0.6, width: r * 2, height: r * 1.2)),
                         with: .color(.white.opacity(0.05)))
            }
        }
    }
}

/// Entering a place: its story, and a lore fragment you discover (chapter 29 §A.4).
struct LocationScene: View {
    let place: Place
    let model: AppModel
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                LinearGradient(colors: [place.color.opacity(0.9), place.color.opacity(0.25), .black], startPoint: .top, endPoint: .bottom)
                Image(systemName: place.icon).font(.system(size: 64)).foregroundStyle(.white.opacity(0.85))
            }
            .frame(height: 220)
            Text(place.name).font(Theme.ceremonial(28))
            Text(place.blurb).font(Theme.ceremonial(17)).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            VStack(alignment: .leading, spacing: 6) {
                Text("Lore discovered").font(.caption).foregroundStyle(Theme.dawn)
                Text(place.lore).font(Theme.ceremonial(16)).italic()
            }
            .padding().frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.06)).padding(.horizontal)
            if place.id == "grove", let ritual = model.ritualCard {
                Text("This week's Ritual gathers here: \(ritual.title)").font(.subheadline).padding(.horizontal)
            }
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
        .preferredColorScheme(.dark)
    }
}
