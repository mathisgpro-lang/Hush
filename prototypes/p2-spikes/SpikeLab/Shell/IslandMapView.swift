// Decision 190: the map is a journey. UIKit owns the scrolling and composited scene; SwiftUI owns only
// the header/cards. The map's progression rules remain in IslandPath.swift.
import SwiftUI

struct IslandMapView: View {
    let model: ShellModel
    @State private var scene = MapJourneyController()
    @State private var selected: RealmID?
    @State private var diving = false
    @State private var zoom: CGFloat = 1
    @State private var zoomAnchor: UnitPoint = .center
    @State private var flash: Double = 0
    @State private var lastTap = CGPoint(x: 200, y: 400)
    @State private var coinTarget = CGPoint(x: 330, y: 70)
    @State private var burst: CoinFlight.Burst?
    @State private var shownEmbers: Int?
    @State private var flightTask: Task<Void, Never>?
    @State private var purchaseTask: Task<Void, Never>?

    var body: some View {
        let _ = PerfProbe.body("IslandMap")
        let path = model.islandPath
        MapJourneyViewport(controller: scene, path: path, form: model.form,
                           ready: model.coreReady, newHere: model.newHere) { realm, point in
            guard !diving else { return }
            lastTap = point
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.sheet) { selected = realm }
        }
        .scaleEffect(zoom, anchor: zoomAnchor)
        .ignoresSafeArea()
        .overlay {
            VStack {
                header
                Spacer()
                if model.tour == .map && !diving {
                    TourBubble(text: "The Emberlands. Each world is an island on your Flame's path, and it opens as your Flame grows. Our first journey is the Whispering Grove.",
                               button: "Fly there", next: {
                        model.tour = .grove
                        selected = .grove
                        enter(.grove)
                    }, skip: { withAnimation { model.tour = nil } })
                    .padding(.bottom, 24)
                } else if let r = selected, !diving {
                    card(r, path).transition(.move(edge: .bottom))
                }
            }.padding(.horizontal, 16)
        }
        .overlay {
            if let b = burst {
                CoinFlight(burst: b, landed: { _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
                }, done: { burst = nil }).id(b.id)
            }
        }
        .onPreferenceChange(EmberTargetKey.self) { p in if let p { coinTarget = p } }
        .overlay {
            ZStack {
                (selected?.color ?? .white).opacity(flash * 0.8)
                Color.white.opacity(flash * 0.6)
            }.ignoresSafeArea().allowsHitTesting(false)
        }
        .onDisappear {
            flightTask?.cancel()
            purchaseTask?.cancel()
            scene.stop()
        }
    }

    private func card(_ r: RealmID, _ path: IslandPath) -> some View {
        let isOpen = model.open.contains(r), ink = Theme.ink
        let state = path.islands.first { $0.realm == r }?.state ?? .sealed
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
            switch state {
            case .open:
                Button { enter(r) } label: { GoldButtonLabel(text: r == .sanctuary ? "Fly home" : "Fly there").frame(maxWidth: .infinity) }
            case .buyable(let price, _):
                let have = model.journey.embers
                Button { buy(r) } label: { GoldButtonLabel(text: "Open it · \(price) Embers").frame(maxWidth: .infinity).opacity(have >= price ? 1 : 0.45) }
                    .disabled(have < price)
                Text(have >= price ? "You have \(have) Embers, all earned by living." : "You have \(have) of \(price) Embers. Every quest, every day kept adds more.")
                    .font(.ui(12)).foregroundStyle(ink.opacity(0.6))
            case .toReach(let level):
                Label("Your Flame reaches it at level \(level) (now level \(path.flameLevel)).", systemImage: "flame.fill")
                    .font(.ui(14, .semibold)).foregroundStyle(ink.opacity(0.7))
            case .waiting(let level):
                if let next = model.journey.nextToBuy(among: ShellModel.builtRealms), next != r {
                    Label("Opens after \(next.name), at level \(level).", systemImage: "lock.fill")
                        .font(.ui(14, .semibold)).foregroundStyle(ink.opacity(0.7))
                } else {
                    Label("Your Flame reaches it at level \(level).", systemImage: "lock.fill")
                        .font(.ui(14, .semibold)).foregroundStyle(ink.opacity(0.7))
                }
            case .sealed:
                Label("Still asleep in the Hush. It wakes with \(r.opensWhen).", systemImage: "moon.zzz.fill")
                    .font(.ui(14)).foregroundStyle(ink.opacity(0.7))
            }
        }
        .padding(20)
        .background(SheetPaper(corner: 24))
        .padding(.bottom, 24)
    }

    /// The purchase still goes through the existing rules; its visual wake belongs to the map scene.
    private func buy(_ r: RealmID) {
        let before = model.journey.embers
        guard model.journey.buy(r, among: ShellModel.builtRealms) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        shownEmbers = before
        withAnimation(.easeOut(duration: 1)) { shownEmbers = model.journey.embers }
        burst = .init(from: coinTarget, to: lastTap, coins: 10, start: Date())
        purchaseTask?.cancel()
        purchaseTask = Task { @MainActor in
            do { try await Task.sleep(for: .milliseconds(1300)) } catch { return }
            guard model.screen == .map else { return }
            shownEmbers = nil
            model.newHere.insert(r)
            scene.wake(r)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    /// Travel is presentation only. Neither a hop nor a dash changes a level or a saved world.
    private func enter(_ r: RealmID) {
        guard !diving, model.open.contains(r) else { return }
        withAnimation(.easeOut(duration: 0.2)) { diving = true }
        selected = r
        scene.travel(to: r) {
            flightTask = Task { @MainActor in
                if r != .sanctuary && !model.realmsBuilt.contains(r) { await model.ensure(.realm(r)) }
                guard !Task.isCancelled, model.screen == .map else { return }
                zoomAnchor = scene.anchor(for: r)
                PerfProbe.shared.phase = "map fly-in"
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                withAnimation(.easeIn(duration: 0.9)) { zoom = 2.6 }
                do { try await Task.sleep(for: .milliseconds(620)) } catch { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(.easeIn(duration: 0.28)) { flash = 1 }
                do { try await Task.sleep(for: .milliseconds(290)) } catch { return }
                guard model.screen == .map else { return }
                model.arrivingByDive = true
                model.go(r == .sanctuary ? .home : .realm(r))
            }
        }
    }

    private var header: some View {
        HStack {
            Button { withAnimation(.screen) { model.go(.home) } } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                    Text("Home").font(.ui(15, .medium))
                }
                .foregroundStyle(Theme.cream).padding(.horizontal, 14).padding(.vertical, 9)
                .background(Capsule(style: .continuous).fill(.black.opacity(0.4)))
                .overlay(Capsule(style: .continuous).stroke(Theme.champagne.opacity(0.35), lineWidth: 0.75))
                .contentShape(Capsule())
            }
            .buttonStyle(PressableStyle())
            Spacer()
            Text("The Emberlands").font(.story(22, .medium)).foregroundStyle(Theme.cream)
                .shadow(color: .black.opacity(0.7), radius: 3, y: 1)
            Spacer()
            EmbersBadge(value: shownEmbers ?? model.journey.embers)
        }
        .padding(.top, 4)
        .background(alignment: .top) {                       // a soft dusk behind the header, so it reads over any island
            LinearGradient(colors: [Color(red: 0.03, green: 0.07, blue: 0.12).opacity(0.85), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 150).padding(.horizontal, -16).offset(y: -60).allowsHitTesting(false)
        }
    }
}

// MARK: - Stable map geometry (shared by scene and hit testing)

struct MapLayout {
    let width: CGFloat, height: CGFloat
    let islandSize: CGFloat
    var islandCenter: [RealmID: CGPoint] = [:]
    private var stoneAt: [Int: CGPoint] = [:]
    var pebbles: [(at: CGPoint, level: Int)] = []
    var islets: [(at: CGPoint, size: CGFloat)] = []
    var clouds: [(at: CGPoint, size: CGFloat, opacity: Double)] = []
    var flame: CGPoint

    func stone(_ level: Int) -> CGPoint { stoneAt[level] ?? .zero }

    init(path: IslandPath, width W: CGFloat) {
        width = W
        // As in Codex's sketch: big islands pushed out to the sides, alternating, and the path winding up the middle
        // between them, from one island's inner edge to the next.
        islandSize = W * 0.68
        let spacing = W * 0.52, bottom = W * 0.56, top = W * 0.70
        let islands = path.islands
        let lastIsland = islands.last?.level ?? 1
        let beyond = CGFloat(max(0, (path.stones.last?.level ?? 1) - lastIsland)) * W * 0.17
        height = bottom + CGFloat(max(0, islands.count - 1)) * spacing + top + beyond
        let xs: [CGFloat] = [0.34, 0.70, 0.30, 0.70, 0.31, 0.69, 0.32, 0.66]
        var docks: [(level: Int, at: CGPoint)] = []
        for (k, i) in islands.enumerated() {
            let c = CGPoint(x: W * xs[k % xs.count], y: height - bottom - CGFloat(k) * spacing)
            islandCenter[i.realm] = c
            // Its own stone sits on its inner edge, toward the middle of the screen where the path runs.
            let inward: CGFloat = c.x < W / 2 ? 1 : -1
            let dock = CGPoint(x: c.x + inward * islandSize * 0.25, y: c.y + islandSize * 0.07)
            stoneAt[i.level] = dock
            docks.append((i.level, dock))
        }
        // The stones between two islands: up the middle, in a gentle S.
        for k in 0..<max(0, docks.count - 1) {
            let a = docks[k], b = docks[k + 1]
            let mid = CGPoint(x: (a.at.x + b.at.x) / 2, y: (a.at.y + b.at.y) / 2)
            let ctrl = CGPoint(x: mid.x + (k.isMultiple(of: 2) ? W * 0.07 : -W * 0.07), y: mid.y)
            func on(_ t: CGFloat) -> CGPoint {
                let u = 1 - t
                return CGPoint(x: u * u * a.at.x + 2 * u * t * ctrl.x + t * t * b.at.x, y: u * u * a.at.y + 2 * u * t * ctrl.y + t * t * b.at.y)
            }
            let n = b.level - a.level
            for j in 1..<max(1, n) { stoneAt[a.level + j] = on(CGFloat(j) / CGFloat(n)) }
            for j in 0..<n {                                     // two pebbles between each pair of stones
                for q in [CGFloat(0.36), CGFloat(0.66)] {
                    pebbles.append((on((CGFloat(j) + q) / CGFloat(n)), a.level + j))
                }
            }
        }
        // Past the last island, the path goes on straight up (a Flame beyond every world).
        if let last = docks.last {
            var level = last.level + 1
            while level <= (path.stones.last?.level ?? 0) {
                stoneAt[level] = CGPoint(x: last.at.x, y: last.at.y - CGFloat(level - last.level) * W * 0.17)
                level += 1
            }
        }
        flame = stoneAt[path.flameStone] ?? .zero
        // The sky: distant islets and drifting clouds, scattered (always the same).
        var rng = SeededRandom(seed: 89)
        var y = height - W * 0.3
        while y > 0 {
            islets.append((CGPoint(x: W * CGFloat.random(in: 0.05...0.95, using: &rng), y: y), W * CGFloat.random(in: 0.10...0.20, using: &rng)))
            if Bool.random(using: &rng) {
                clouds.append((CGPoint(x: W * CGFloat.random(in: 0.0...1.0, using: &rng), y: y - W * 0.3), W * CGFloat.random(in: 0.45...0.8, using: &rng),
                               Double.random(in: 0.25...0.5, using: &rng)))
            }
            y -= W * CGFloat.random(in: 0.42...0.62, using: &rng)
        }
    }
}

