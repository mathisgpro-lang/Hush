// The world map as a road (decision 105: Duolingo path / Plants vs. Zombies world map). Codex's painted map scrolls
// from the Sanctuary in the sea up to the Veil; a glowing road links the realms in the order they open; open realms
// glow, the newest pulses with a badge, locked ones sit in the grey Hush with what opens them. Tap a realm: your
// Flame travels along the road, then the map zooms into that world.
import SwiftUI

let roadOrder: [RealmID] = [.sanctuary, .grove, .stillwater, .highlands, .library, .wilds, .forge, .veil]

/// The road follows the paths painted on Codex's map: waypoints (map pixels) with the realm each stop belongs to.
let roadPoints: [(p: CGPoint, stop: RealmID?)] = [
    (RealmID.sanctuary.mapPoint, .sanctuary), (CGPoint(x: 425, y: 1410), nil), (CGPoint(x: 420, y: 1325), nil),
    (CGPoint(x: 345, y: 1205), nil), (CGPoint(x: 300, y: 1115), nil), (CGPoint(x: 235, y: 1045), nil),
    (RealmID.grove.mapPoint, .grove), (CGPoint(x: 300, y: 975), nil), (CGPoint(x: 450, y: 925), nil),
    (CGPoint(x: 600, y: 945), nil), (RealmID.stillwater.mapPoint, .stillwater), (CGPoint(x: 565, y: 860), nil),
    (CGPoint(x: 525, y: 785), nil), (CGPoint(x: 560, y: 700), nil), (RealmID.highlands.mapPoint, .highlands),
    (CGPoint(x: 520, y: 565), nil), (CGPoint(x: 400, y: 525), nil), (CGPoint(x: 265, y: 500), nil),
    (RealmID.library.mapPoint, .library), (CGPoint(x: 300, y: 430), nil), (CGPoint(x: 450, y: 420), nil),
    (CGPoint(x: 585, y: 410), nil), (RealmID.wilds.mapPoint, .wilds), (CGPoint(x: 600, y: 330), nil),
    (CGPoint(x: 520, y: 270), nil), (RealmID.forge.mapPoint, .forge), (CGPoint(x: 500, y: 150), nil),
    (RealmID.veil.mapPoint, .veil),
]
func roadIndex(_ r: RealmID) -> Int { roadPoints.firstIndex { $0.stop == r } ?? 0 }

struct RoadMapView: View {
    let model: ShellModel
    @State private var token: CGPoint?            // the Flame on the map, in map pixels
    @State private var traveling = false
    @State private var zoom: (anchor: UnitPoint, scale: CGFloat) = (.center, 1)
    @State private var toast: String?
    @State private var pulse = false
    private let mapSize = CGSize(width: 803, height: 1958)

    var body: some View {
        GeometryReader { geo in
            let k = geo.size.width / mapSize.width                 // map pixels → points
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()
                ScrollViewReader { reader in
                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            Image(uiImage: UIImage(named: "world-map.png") ?? UIImage()).resizable().frame(width: geo.size.width, height: mapSize.height * k)
                            hush(k)
                            road(k)
                            ForEach(roadOrder) { r in node(r, k: k).position(x: r.mapPoint.x * k, y: r.mapPoint.y * k) }
                            flameToken.position(x: ((token ?? model.flameAt.mapPoint).x + 62) * k, y: ((token ?? model.flameAt.mapPoint).y - 40) * k)
                            Color.clear.frame(width: 1, height: 1).position(x: 0, y: (mapSize.height - 260) * k).id("bottom")
                        }
                        .frame(width: geo.size.width, height: mapSize.height * k)
                    }
                    .scrollDisabled(traveling)
                    .onAppear { reader.scrollTo("bottom", anchor: .bottom) }
                }
                .scaleEffect(zoom.scale, anchor: zoom.anchor)
                .ignoresSafeArea()

                header
                if let toast {
                    VStack { Spacer(); Text(toast).font(.system(size: 15, design: .serif)).padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(.black.opacity(0.7))).foregroundStyle(.white).padding(.bottom, 60) }
                    .transition(.opacity)
                }
            }
        }
        .onAppear { pulse = true }
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
        .padding(.horizontal, 16).padding(.top, 4)
    }

    // The Hush over locked realms: grey mist, nothing destroyed.
    private func hush(_ k: CGFloat) -> some View {
        ForEach(roadOrder.filter { !model.open.contains($0) }) { r in
            Circle().fill(RadialGradient(colors: [Color(white: 0.62).opacity(0.85), Color(white: 0.55).opacity(0.5), .clear],
                                         center: .center, startRadius: 10, endRadius: 190 * k))
                .frame(width: 380 * k, height: 380 * k)
                .position(x: r.mapPoint.x * k, y: r.mapPoint.y * k)
                .blendMode(.screen).allowsHitTesting(false)
        }
    }

    // The road: lit gold up to the last open realm, a faint dotted line beyond.
    private func road(_ k: CGFloat) -> some View {
        let pts = roadPoints.map { CGPoint(x: $0.p.x * k, y: $0.p.y * k) }
        let lastOpen = roadIndex(roadOrder.last { model.open.contains($0) } ?? .sanctuary)
        return ZStack {
            smooth(Array(pts[lastOpen...])).stroke(Color.white.opacity(0.45), style: .init(lineWidth: 3, lineCap: .round, dash: [2, 9]))
            smooth(Array(pts[...lastOpen])).stroke(Color(red: 1, green: 0.78, blue: 0.4), style: .init(lineWidth: 6, lineCap: .round))
                .shadow(color: Color(red: 1, green: 0.6, blue: 0.2), radius: pulse ? 10 : 4)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
        }
        .allowsHitTesting(false)
    }

    private func node(_ r: RealmID, k: CGFloat) -> some View {
        let isOpen = model.open.contains(r), isNew = model.newHere.contains(r)
        return Button { tapped(r, k: k) } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(isOpen ? r.color : Color(white: 0.35)).frame(width: 54, height: 54)
                        .shadow(color: isOpen ? r.color : .clear, radius: isNew && pulse ? 18 : 8)
                    Circle().stroke(.white.opacity(isOpen ? 0.9 : 0.4), lineWidth: 2.5).frame(width: 54, height: 54)
                    Image(systemName: isOpen ? r.symbol : "lock.fill").font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isOpen ? .white : .white.opacity(0.7))
                    if isNew {
                        Text("NEW").font(.system(size: 10, weight: .heavy)).padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color(red: 1, green: 0.45, blue: 0.2))).foregroundStyle(.white).offset(x: 24, y: -24)
                    }
                }
                .scaleEffect(isNew && pulse ? 1.08 : 1)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
                Text(r.name).font(.system(size: 12, weight: .semibold, design: .serif))
                    .padding(.horizontal, 8).padding(.vertical, 3).background(Capsule().fill(.black.opacity(0.6))).foregroundStyle(.white)
                if !isOpen { Text("Opens with \(r.opensWhen)").font(.system(size: 10, design: .serif)).foregroundStyle(.white.opacity(0.8)) }
            }
        }
        .buttonStyle(.plain)
    }

    private var flameToken: some View {
        Image(uiImage: UIImage(named: "hero-keyed.png") ?? UIImage()).resizable().scaledToFit().frame(width: 46)
            .shadow(color: Color(red: 1, green: 0.6, blue: 0.2), radius: 10)
            .offset(y: pulse ? -4 : 2)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
            .allowsHitTesting(false)
    }

    private func tapped(_ r: RealmID, k: CGFloat) {
        guard !traveling else { return }
        guard model.open.contains(r) else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            withAnimation { toast = "\(r.name) is still in the Hush. It opens with \(r.opensWhen)." }
            Task { @MainActor in try? await Task.sleep(for: .seconds(2.6)); withAnimation { toast = nil } }
            return
        }
        traveling = true
        // Travel along the road from where the Flame is to the chosen realm.
        let a = roadIndex(model.flameAt), b = roadIndex(r)
        let stops = (a <= b ? Array(roadPoints[a...b]) : Array(roadPoints[b...a].reversed())).map(\.p)
        Task { @MainActor in
            for i in 0..<(stops.count - 1) {
                let p0 = stops[i], p1 = stops[i + 1]
                for s in 1...10 {
                    let t = CGFloat(s) / 10, e = t
                    token = CGPoint(x: p0.x + (p1.x - p0.x) * e, y: p0.y + (p1.y - p0.y) * e)
                    try? await Task.sleep(for: .milliseconds(22))
                }
            }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            // Zoom into the world.
            withAnimation(.easeIn(duration: 0.7)) { zoom = (.center, 3.2) }
            try? await Task.sleep(for: .milliseconds(550))
            withAnimation(.easeInOut(duration: 0.5)) { model.go(r == .sanctuary ? .home : .realm(r)) }
            traveling = false
        }
    }

    /// A smooth curve through points (Catmull-Rom → cubic Bézier).
    private func smooth(_ p: [CGPoint]) -> Path {
        Path { path in
            guard p.count > 1 else { return }
            path.move(to: p[0])
            for i in 0..<(p.count - 1) {
                let p0 = i > 0 ? p[i - 1] : p[i], p1 = p[i], p2 = p[i + 1], p3 = i + 2 < p.count ? p[i + 2] : p[i + 1]
                let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
                let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
                path.addCurve(to: p2, control1: c1, control2: c2)
            }
        }
    }
}
