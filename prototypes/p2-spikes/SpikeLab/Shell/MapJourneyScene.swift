// Decision 190. A single display link moves composited layers, never the SwiftUI map tree.
// UIScrollView supplies touch tracking, momentum and rubber-banding. Artwork and text are decoded/rasterized
// once; only visible islands move. No live image filters, blurred layer shadows, or per-object animators.
import SwiftUI
import UIKit

@MainActor
final class MapJourneyController {
    fileprivate weak var view: MapJourneyView?
    func travel(to realm: RealmID, arrived: @escaping () -> Void) { view?.travel(to: realm, arrived: arrived) }
    func wake(_ realm: RealmID) { view?.wake(realm) }
    func anchor(for realm: RealmID) -> UnitPoint { view?.anchor(for: realm) ?? .center }
    func stop() { view?.stop() }
}

struct MapJourneyViewport: UIViewRepresentable {
    let controller: MapJourneyController
    let path: IslandPath
    let form: Evolution
    let ready: Bool
    let newHere: Set<RealmID>
    let select: (RealmID, CGPoint) -> Void

    func makeUIView(context: Context) -> MapJourneyView {
        let view = MapJourneyView()
        controller.view = view
        return view
    }
    func updateUIView(_ view: MapJourneyView, context: Context) {
        view.select = select
        view.configure(path: path, form: form, ready: ready, newHere: newHere)
    }
    static func dismantleUIView(_ view: MapJourneyView, coordinator: ()) { view.stop() }
}

@MainActor
private final class MapDisplayLinkTarget: NSObject {
    weak var view: MapJourneyView?
    @objc func tick(_ link: CADisplayLink) { view?.tick(link) }
}

@MainActor
final class MapJourneyView: UIView, UIScrollViewDelegate {
    private enum Motion { case idle, progress, travel, inPlace }
    private struct IslandLayers {
        let art: CALayer, title: CALayer, badge: CALayer, mist: CALayer
    }
    private struct Cloud {
        let layer: CALayer
        let x: CGFloat, y: CGFloat, depth: CGFloat, speed: CGFloat
    }
    private struct CameraMove {
        let from: CGFloat, to: CGFloat
        let start: Double, duration: Double
    }
    private let scroll = UIScrollView()
    private let world = UIView()
    private let sky = CALayer()
    private let far = CALayer()
    private let near = CALayer()
    private let flame = CALayer()
    private let contact = CALayer()
    private let ring = CALayer()
    private let wakeLight = CALayer()
    private var dust: [CALayer] = []
    private var trails: [CALayer] = []
    private var cinders: [CALayer] = []
    private var islands: [RealmID: IslandLayers] = [:]
    private var stones: [Int: CALayer] = [:]
    private var pebbles: [(CALayer, Int)] = []
    private var clouds: [Cloud] = []
    private var rocks: [(CALayer, CGPoint)] = []
    private var path: IslandPath?
    private var map: MapLayout?
    private var form: Evolution = .spark
    private var newHere: Set<RealmID> = []
    private var ready = false, started = false
    private var link: CADisplayLink?
    private let linkTarget = MapDisplayLinkTarget()
    private var lastTimestamp: Double = 0, clock: Double = 0
    private var motion: Motion = .idle
    private var route: [Int] = []
    private var segment = 0, stoneLevel = 1, displayLevel = 1
    private var segmentStart: Double = 0
    private var didLand = false, isDash = false
    private var cameraMove: CameraMove?
    private var pendingTravel: (RealmID, () -> Void)?
    private var arrival: (() -> Void)?
    private var settleUntil: Double?
    private var wakeStart: Double = -100, dustStart: Double = -100
    private var wakeRealm: RealmID?
    private var dustPoint = CGPoint.zero, flamePoint = CGPoint.zero
    private var automatedStep = 0, automatedAt: Double = 0
    var select: ((RealmID, CGPoint) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = UIColor(red: 0.15, green: 0.20, blue: 0.34, alpha: 1)
        layer.addSublayer(sky)
        layer.addSublayer(far)
        addSubview(scroll)
        layer.addSublayer(near)
        scroll.addSubview(world)
        scroll.delegate = self
        scroll.showsVerticalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        scroll.alwaysBounceVertical = true
        scroll.decelerationRate = .normal
        scroll.backgroundColor = .clear
        scroll.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
        sky.contents = MapSceneArt.image("map-sky-dusk", ext: "jpg")
        sky.contentsGravity = .resizeAspectFill
        sky.masksToBounds = true
        linkTarget.view = self
        NotificationCenter.default.addObserver(self, selector: #selector(backgrounded), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(foregrounded), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(path: IslandPath, form: Evolution, ready: Bool, newHere: Set<RealmID>) {
        let changed = self.path != path || self.newHere != newHere
        let levelChanged = self.path?.flameLevel != path.flameLevel
        self.path = path
        self.ready = ready
        self.newHere = newHere
        if self.form != form || flame.contents == nil {
            self.form = form
            flame.contents = MapSceneArt.image(form.base + "-keyed")
            let image = UIImage(named: form.base + "-keyed.png")
            let ratio = (image?.size.width ?? 270) / (image?.size.height ?? 342)
            flame.bounds = CGRect(x: 0, y: 0, width: 38 * ratio, height: 38)
            flame.anchorPoint = CGPoint(x: 0.5, y: 0.96)
        }
        if levelChanged { started = false }
        if changed, map != nil { refreshIslands(); refreshStones() }
        setNeedsLayout()
        startIfReady()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0, let path else { return }
        CATransaction.begin(); CATransaction.setDisableActions(true)
        scroll.frame = bounds
        far.frame = bounds; near.frame = bounds
        // A single opaque plate has no repeating seams. Its extra height gives the far sky slow parallax.
        sky.frame = CGRect(x: 0, y: -70, width: bounds.width, height: bounds.height + 140)
        if map?.width != bounds.width {
            map = MapLayout(path: path, width: bounds.width)
            buildScene()
            started = false
        }
        CATransaction.commit()
        startIfReady()
    }

    private func buildScene() {
        guard let map, let path else { return }
        world.frame = CGRect(x: 0, y: 0, width: map.width, height: map.height)
        scroll.contentSize = world.bounds.size
        world.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        far.sublayers?.forEach { $0.removeFromSuperlayer() }
        near.sublayers?.forEach { $0.removeFromSuperlayer() }
        islands.removeAll(); stones.removeAll(); pebbles.removeAll(); clouds.removeAll(); rocks.removeAll()
        for (k, p) in map.islets.enumerated() {
            let rock = sprite("map-islet", size: CGSize(width: p.size, height: p.size), parent: far)
            rock.opacity = 0.30 + Float(k % 3) * 0.06
            rocks.append((rock, p.at))
        }
        for k in 0..<7 {
            let depth: CGFloat = k < 4 ? 0.24 : 0.63
            let width = bounds.width * (k < 4 ? 1.12 : 0.94)
            let cloud = sprite("map-sky-wisp", size: CGSize(width: width, height: width * 215 / 800), parent: k < 4 ? far : near)
            cloud.opacity = k < 4 ? 0.22 : 0.15
            clouds.append(Cloud(layer: cloud, x: bounds.width * (k % 2 == 0 ? 0.1 : 0.92),
                                y: CGFloat(k) * 247, depth: depth, speed: k % 2 == 0 ? 1 : -1))
        }
        for i in path.islands.reversed() {
            let size = CGSize(width: map.islandSize, height: map.islandSize)
            let art = sprite("island-" + i.realm.rawValue, size: size, parent: world.layer)
            art.position = map.islandCenter[i.realm] ?? .zero
            let mist = sprite("map-cloud", size: CGSize(width: size.width * 0.8, height: size.height * 0.8), parent: world.layer)
            mist.position = CGPoint(x: art.position.x, y: art.position.y + size.height * 0.16)
            let title = CALayer(), badge = CALayer()
            islands[i.realm] = IslandLayers(art: art, title: title, badge: badge, mist: mist)
        }
        for p in map.pebbles {
            let rock = sprite("map-stone-ahead", size: CGSize(width: 18, height: 18), parent: world.layer)
            rock.position = p.at
            pebbles.append((rock, p.level))
        }
        for stone in path.stones {
            let tile = CALayer()
            tile.bounds = CGRect(x: 0, y: 0, width: 62, height: 66)
            tile.position = map.stone(stone.level)
            world.layer.addSublayer(tile)
            stones[stone.level] = tile
        }
        for i in path.islands {
            guard let parts = islands[i.realm], let at = map.islandCenter[i.realm] else { continue }
            let x = min(map.width - 86, max(86, at.x + (at.x < map.width / 2 ? -1 : 1) * 10))
            parts.title.position = CGPoint(x: x, y: at.y + map.islandSize * 0.31)
            parts.badge.position = CGPoint(x: x, y: parts.title.position.y + 29)
            world.layer.addSublayer(parts.title); world.layer.addSublayer(parts.badge)
        }
        ring.contents = MapSceneArt.halo.cgImage
        ring.bounds = CGRect(x: 0, y: 0, width: 64, height: 27)
        world.layer.addSublayer(ring)
        contact.contents = MapSceneArt.contact.cgImage
        contact.bounds = CGRect(x: 0, y: 0, width: 29, height: 10)
        world.layer.addSublayer(contact)
        trails = (0..<5).map { _ in
            let l = CALayer(); l.contents = MapSceneArt.halo.cgImage
            l.bounds = CGRect(x: 0, y: 0, width: 22, height: 13)
            l.opacity = 0; world.layer.addSublayer(l); return l
        }
        world.layer.addSublayer(flame)
        dust = (0..<7).map { _ in particle(size: 4, color: UIColor(red: 0.94, green: 0.81, blue: 0.56, alpha: 1)) }
        cinders = (0..<3).map { _ in particle(size: 2, color: UIColor(red: 1, green: 0.85, blue: 0.52, alpha: 1)) }
        wakeLight.contents = MapSceneArt.halo.cgImage
        wakeLight.bounds = CGRect(x: 0, y: 0, width: map.islandSize, height: map.islandSize)
        wakeLight.opacity = 0
        world.layer.addSublayer(wakeLight)
        refreshIslands(); refreshStones()
    }

    private func startIfReady() {
        guard ready, let path, let map, window != nil else { return }
        if !started {
            started = true
            let current = max(1, path.flameStone)
            let previous = UserDefaults.standard.object(forKey: "map.lastLevel") as? Int
            let old = previous.map { max(1, min($0, current)) } ?? current
            displayLevel = old; stoneLevel = old; flamePoint = map.stone(old)
            CATransaction.begin(); CATransaction.setDisableActions(true)
            scroll.contentOffset.y = MapJourneyMotion.cameraY(for: flamePoint, viewportHeight: bounds.height, contentHeight: map.height)
            refreshIslands(); refreshStones()
            placeFlame(MapJourneyMotion.hop(from: flamePoint, to: flamePoint, progress: 0))
            CATransaction.commit()
            if old < current {
                beginRoute(Array(old...current), motion: .progress, delay: 0.75)
            } else {
                UserDefaults.standard.set(path.flameLevel, forKey: "map.lastLevel")
                motion = .idle
                PerfProbe.shared.phase = "map idle"
            }
        }
        if link == nil {
            let l = CADisplayLink(target: linkTarget, selector: #selector(MapDisplayLinkTarget.tick(_:)))
            l.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
            l.add(to: .main, forMode: .common)
            link = l
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { stop() } else { startIfReady() }
    }
    func stop() {
        link?.invalidate(); link = nil; lastTimestamp = 0
        pendingTravel = nil; arrival = nil
    }
    @objc private func backgrounded() { link?.isPaused = true; lastTimestamp = 0 }
    @objc private func foregrounded() { link?.isPaused = false; lastTimestamp = 0 }

    func travel(to realm: RealmID, arrived: @escaping () -> Void) {
        guard let path, path.islands.contains(where: { $0.realm == realm && $0.state == .open }) else { return }
        if motion != .idle || !started || settleUntil != nil {
            pendingTravel = (realm, arrived); return
        }
        arrival = arrived
        let destination = realm.islandLevel
        let steps = stoneLevel <= destination ? Array(stoneLevel...destination) : Array((destination...stoneLevel).reversed())
        isDash = abs(destination - stoneLevel) > 4
        if let map {
            let target = MapJourneyMotion.cameraY(for: map.stone(stoneLevel), viewportHeight: bounds.height, contentHeight: map.height)
            cameraMove = CameraMove(from: scroll.contentOffset.y, to: target, start: clock, duration: 0.38)
        }
        beginRoute(steps, motion: .travel, delay: 0.4)
    }

    private func beginRoute(_ levels: [Int], motion: Motion, delay: Double = 0) {
        route = levels; segment = 0; didLand = false
        self.motion = motion
        if motion != .travel { isDash = false }
        segmentStart = clock + delay
        scroll.isScrollEnabled = false
        PerfProbe.shared.phase = motion == .progress ? "map progress walk" : (isDash ? "map dash" : "map hops")
    }

    func wake(_ realm: RealmID) {
        wakeRealm = realm; wakeStart = clock
        if let at = map?.islandCenter[realm] { wakeLight.position = at }
    }

    func anchor(for realm: RealmID) -> UnitPoint {
        guard let at = map?.islandCenter[realm] else { return .center }
        return UnitPoint(x: at.x / max(1, bounds.width), y: (at.y - scroll.contentOffset.y) / max(1, bounds.height))
    }

    fileprivate func tick(_ link: CADisplayLink) {
        guard ready, let map else { return }
        let dt = lastTimestamp == 0 ? 1 / 60.0 : min(0.04, max(0, link.timestamp - lastTimestamp))
        lastTimestamp = link.timestamp; clock += dt
        CATransaction.begin(); CATransaction.setDisableActions(true)
        animateTravel()
        if let move = cameraMove {
            let t = CGFloat((clock - move.start) / move.duration)
            scroll.contentOffset.y = move.from + (move.to - move.from) * MapJourneyMotion.ease(t)
            if t >= 1 { cameraMove = nil }
        } else if motion != .idle || settleUntil != nil {
            let target = MapJourneyMotion.cameraY(for: flamePoint, viewportHeight: bounds.height, contentHeight: map.height)
            scroll.contentOffset.y += (target - scroll.contentOffset.y) * CGFloat(1 - exp(-dt * 11))
        }
        animateAtmosphere()
        animateParticles()
        CATransaction.commit()
        if let until = settleUntil, clock >= until {
            settleUntil = nil
            let done = arrival; arrival = nil
            done?()
            if done == nil { scroll.isScrollEnabled = true }
        }
        if motion == .idle, settleUntil == nil, let pending = pendingTravel {
            pendingTravel = nil
            travel(to: pending.0, arrived: pending.1)
        }
        runVerificationTour()
    }

    private func animateTravel() {
        guard let map else { return }
        if motion == .idle {
            let p = map.stone(stoneLevel)
            placeFlame(MapHopPose(point: p, elevation: 0, scaleX: 1 + 0.012 * sin(clock * 2.8),
                                 scaleY: 1 + 0.018 * sin(clock * 2.8 + 0.7), rotation: 0))
            return
        }
        guard clock >= segmentStart else { return }
        if route.count < 2 { finishRoute(); return }
        let duration = isDash ? 0.94 : (motion == .travel ? 0.34 : 0.56)
        let progress = min(1, CGFloat((clock - segmentStart) / duration))
        let from = map.stone(route[segment]), to = map.stone(route[segment + 1])
        let pose = isDash ? MapJourneyMotion.dash(points: route.map(map.stone), progress: progress)
                          : MapJourneyMotion.hop(from: from, to: to, progress: progress)
        placeFlame(pose)
        if isDash {
            for (k, trail) in trails.enumerated() {
                let earlier = max(0, progress - CGFloat(k + 1) * 0.026)
                let p = MapJourneyMotion.dash(points: route.map(map.stone), progress: earlier)
                trail.position = CGPoint(x: p.point.x, y: p.point.y - p.elevation - 23)
                trail.opacity = Float(0.34 - Double(k) * 0.05) * Float(sin(.pi * progress))
            }
        }
        if !didLand && progress >= (isDash ? 1 : 0.82) {
            didLand = true
            stoneLevel = isDash ? (route.last ?? stoneLevel) : route[segment + 1]
            dustPoint = map.stone(stoneLevel); dustStart = clock
            if motion == .progress {
                displayLevel = stoneLevel
                UserDefaults.standard.set(displayLevel, forKey: "map.lastLevel")
                refreshStones(); refreshIslands()
                if let island = path?.islands.first(where: { $0.level == stoneLevel }) { wake(island.realm) }
            }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: motion == .progress ? 0.5 : 0.3)
        }
        if progress >= 1 {
            if isDash || segment + 2 >= route.count { finishRoute() }
            else { segment += 1; segmentStart = clock; didLand = false }
        }
    }

    private func finishRoute() {
        if let last = route.last { stoneLevel = last }
        let wasTravel = motion == .travel
        motion = .idle; isDash = false
        trails.forEach { $0.opacity = 0 }
        settleUntil = clock + (wasTravel ? 0.3 : 0.16)
        if !wasTravel { PerfProbe.shared.phase = "map idle" }
    }

    private func placeFlame(_ pose: MapHopPose) {
        flamePoint = pose.point
        let foot = CGPoint(x: pose.point.x, y: pose.point.y - 13)
        flame.position = CGPoint(x: foot.x, y: foot.y - pose.elevation)
        flame.setAffineTransform(CGAffineTransform(rotationAngle: pose.rotation).scaledBy(x: pose.scaleX, y: pose.scaleY))
        contact.position = foot
        let shrink = max(0.48, 1 - pose.elevation / 90)
        contact.setAffineTransform(CGAffineTransform(scaleX: shrink, y: shrink))
        contact.opacity = Float(0.8 - min(0.4, pose.elevation / 100))
        ring.position = CGPoint(x: foot.x, y: foot.y + 3)
        ring.opacity = Float(0.35 + 0.08 * sin(clock * 2.1))
    }

    private func animateAtmosphere() {
        guard let map else { return }
        let offset = scroll.contentOffset.y
        let visible = CGRect(x: 0, y: offset - 90, width: bounds.width, height: bounds.height + 180)
        sky.transform = CATransform3DMakeTranslation(0, (offset / max(1, map.height - bounds.height) - 0.5) * -60, 0)
        for (k, i) in (path?.islands ?? []).enumerated() {
            guard let parts = islands[i.realm], let at = map.islandCenter[i.realm] else { continue }
            let shown = visible.intersects(CGRect(x: at.x - map.islandSize / 2, y: at.y - map.islandSize / 2, width: map.islandSize, height: map.islandSize))
            parts.art.isHidden = !shown; parts.mist.isHidden = !shown
            parts.title.isHidden = !shown; parts.badge.isHidden = !shown
            guard shown else { continue }
            let bob = CGFloat(sin(clock * (0.72 + Double(k) * 0.04) + Double(k) * 1.3)) * 2
            parts.art.transform = CATransform3DMakeTranslation(0, bob, 0)
            parts.mist.transform = CATransform3DMakeTranslation(CGFloat(sin(clock * 0.15 + Double(k))) * 9, bob, 0)
        }
        for (rock, p) in rocks {
            let y = p.y * 0.58 - offset * 0.33
            rock.isHidden = y < -80 || y > bounds.height + 80
            if !rock.isHidden { rock.position = CGPoint(x: p.x, y: y + CGFloat(sin(clock * 0.3 + Double(p.x))) * 3) }
        }
        for c in clouds {
            let span = bounds.height + 320
            var y = (c.y - offset * c.depth).truncatingRemainder(dividingBy: span)
            if y < -160 { y += span }
            if y > bounds.height + 160 { y -= span }
            c.layer.position = CGPoint(x: c.x + CGFloat(sin(clock * 0.035)) * 32 * c.speed, y: y)
        }
        let wake = (clock - wakeStart) / 1.25
        if wake < 1, wake >= 0 {
            wakeLight.opacity = Float(sin(.pi * wake)) * 0.34
            wakeLight.setAffineTransform(CGAffineTransform(scaleX: 0.65 + wake * 0.55, y: 0.65 + wake * 0.55))
            if let r = wakeRealm, let badge = islands[r]?.badge {
                badge.opacity = Float(min(1, wake * 4))
                badge.setAffineTransform(CGAffineTransform(scaleX: 0.85 + min(1, wake * 3) * 0.15, y: 0.85 + min(1, wake * 3) * 0.15))
            }
        } else { wakeLight.opacity = 0 }
    }

    private func animateParticles() {
        let t = (clock - dustStart) / 0.42
        for (k, p) in dust.enumerated() {
            p.opacity = t >= 0 && t < 1 ? Float(1 - t) * 0.7 : 0
            guard t < 1 else { continue }
            let side = CGFloat(k) - 3
            p.position = CGPoint(x: dustPoint.x + side * (3 + t * 5), y: dustPoint.y - 12 - sin(t * .pi) * CGFloat(4 + k % 3 * 3))
            p.setAffineTransform(CGAffineTransform(scaleX: 1 + t, y: 1 + t))
        }
        for (k, p) in cinders.enumerated() {
            let t = (clock * 0.42 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
            p.position = CGPoint(x: flame.position.x + sin(t * 5 + Double(k) * 2) * 6, y: flame.position.y - 30 - t * 20)
            p.opacity = Float(sin(t * .pi)) * 0.55
        }
    }

    private func refreshStones() {
        for (level, tile) in stones {
            tile.contents = MapSceneArt.stone(level: level, lit: level <= displayLevel).cgImage
        }
        for (tile, level) in pebbles { tile.contents = MapSceneArt.image(level < displayLevel ? "map-stone" : "map-stone-ahead") }
    }

    private func refreshIslands() {
        guard let path else { return }
        for i in path.islands {
            guard let parts = islands[i.realm] else { continue }
            let unreached = i.level > displayLevel
            let suffix: String
            var badge: String
            switch i.state {
            case .open: suffix = ""; badge = newHere.contains(i.realm) ? "something new" : ""
            case .buyable(let price, _): suffix = unreached ? "-unreached" : ""; badge = unreached ? "Level \(i.level)" : "◉  \(price)   ·   Buy"
            case .toReach(let level): suffix = "-unreached"; badge = "Level \(level)"
            case .waiting(let level): suffix = "-waiting"; badge = "⌑  Level \(level)"
            case .sealed: suffix = ""; badge = "Sealed"
            }
            parts.art.contents = MapSceneArt.image("island-" + i.realm.rawValue + suffix)
            if case .waiting = i.state { parts.mist.opacity = 0.28 } else { parts.mist.opacity = 0 }
            let title = MapSceneArt.plate(i.realm.name, small: false)
            parts.title.contents = title.cgImage; parts.title.bounds = CGRect(origin: .zero, size: title.size)
            let badgeImage = MapSceneArt.plate(badge, small: true)
            parts.badge.contents = badgeImage.cgImage; parts.badge.bounds = CGRect(origin: .zero, size: badgeImage.size)
            parts.badge.opacity = badge.isEmpty ? 0 : 1
        }
    }

    @objc private func tapped(_ gesture: UITapGestureRecognizer) {
        guard motion == .idle, arrival == nil, settleUntil == nil, let map, let path else { return }
        let p = gesture.location(in: world)
        if hypot(p.x - flamePoint.x, p.y - (flamePoint.y - 27)) < 32 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.55)
            beginRoute([stoneLevel, stoneLevel], motion: .inPlace)
            return
        }
        // Nearest island wins where the art's transparent rectangles overlap. Labels share its hit target.
        let candidates = path.islands.filter { i in
            guard let c = map.islandCenter[i.realm] else { return false }
            let dx = (p.x - c.x) / (map.islandSize * 0.43), dy = (p.y - c.y) / (map.islandSize * 0.45)
            let plate = islands[i.realm]?.title.frame.insetBy(dx: -4, dy: -6) ?? .zero
            let badge = islands[i.realm]?.badge.frame.insetBy(dx: -8, dy: -8) ?? .zero
            return dx * dx + dy * dy <= 1 || plate.contains(p) || badge.contains(p)
        }
        if let island = candidates.min(by: {
            abs((map.islandCenter[$0.realm]?.y ?? 0) - p.y) < abs((map.islandCenter[$1.realm]?.y ?? 0) - p.y)
        }) { select?(island.realm, gesture.location(in: nil)) }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { cameraMove = nil; PerfProbe.shared.phase = "map scrolling" }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { PerfProbe.shared.phase = "map idle" }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { PerfProbe.shared.phase = "map idle" }
    }

    private func sprite(_ name: String, size: CGSize, parent: CALayer) -> CALayer {
        let l = CALayer(); l.contents = MapSceneArt.image(name)
        l.bounds = CGRect(origin: .zero, size: size); l.contentsGravity = .resizeAspect
        parent.addSublayer(l); return l
    }
    private func particle(size: CGFloat, color: UIColor) -> CALayer {
        let l = CALayer(); l.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        l.backgroundColor = color.cgColor; l.cornerRadius = size / 2; l.opacity = 0
        world.layer.addSublayer(l); return l
    }

    /// Reproducible presentation-only exercise for -perf: camera, in-place hop and a world selection.
    /// The normal launch flags are unchanged. No game record is seeded/reset by this flag.
    private func runVerificationTour() {
        guard CommandLine.arguments.contains("-mapjourneytest"), motion == .idle, settleUntil == nil,
              clock >= automatedAt, let map else { return }
        switch automatedStep {
        case 0: automatedAt = clock + 3
        case 1, 2:
            let target: CGFloat = automatedStep == 1 ? 0 : MapJourneyMotion.cameraY(for: map.stone(stoneLevel), viewportHeight: bounds.height, contentHeight: map.height)
            cameraMove = CameraMove(from: scroll.contentOffset.y, to: target, start: clock, duration: 1.6)
            PerfProbe.shared.phase = "map scripted scroll"
            automatedAt = clock + 2.5
        case 3:
            beginRoute([stoneLevel, stoneLevel], motion: .inPlace); automatedAt = clock + 2
        case 4:
            if let r = path?.islands.last(where: { $0.state == .open })?.realm, let at = map.islandCenter[r] {
                select?(r, CGPoint(x: at.x, y: at.y - scroll.contentOffset.y))
            }
            automatedAt = .greatestFiniteMagnitude
        default: return
        }
        automatedStep += 1
    }
}

/// Small raster elements are drawn once, at device scale. Large paintings already contain their color grading.
@MainActor
enum MapSceneArt {
    static var cache: [String: UIImage] = [:]
    /// A painting, already decoded if `prepare()` ran (a painting decoded the first time it comes into view costs a
    /// dropped frame or two: the first walk along the path dipped to ~45 fps on the iPhone 15 before this).
    static func image(_ name: String, ext: String = "png") -> CGImage? {
        if let i = cache[name + "." + ext] { return i.cgImage }
        return UIImage(named: name + "." + ext)?.cgImage
    }
    /// Decodes every map painting off the main thread while the app loads (ShellModel.preloadCore).
    static func prepare(forms: [Evolution]) async {
        var names = ["map-sky-dusk.jpg", "map-stone.png", "map-stone-ahead.png", "map-sky-wisp.png", "map-cloud.png", "map-islet.png"]
        for r in RealmID.allCases { for s in ["", "-waiting", "-unreached"] { names.append("island-\(r.rawValue)\(s).png") } }
        names += forms.map { $0.base + "-keyed.png" }
        let todo = names.filter { cache[$0] == nil }
        let decoded: [(String, UIImage)] = await Task.detached(priority: .utility) {
            todo.compactMap { n in UIImage(named: n).flatMap { i in (i.preparingForDisplay() ?? i) }.map { (n, $0) } }
        }.value
        for (n, i) in decoded { cache[n] = i }
    }
    static let contact = radial(size: 64, color: UIColor.black.withAlphaComponent(0.5))
    static let halo = radial(size: 128, color: UIColor(red: 1, green: 0.80, blue: 0.39, alpha: 0.85))
    static func radial(size: CGFloat, color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { context in
            let colors = [color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray
            guard let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
            context.cgContext.drawRadialGradient(g, startCenter: CGPoint(x: size / 2, y: size / 2), startRadius: 0,
                                                endCenter: CGPoint(x: size / 2, y: size / 2), endRadius: size / 2, options: [])
        }
    }
    static func stone(level: Int, lit: Bool) -> UIImage {
        let key = "stone-\(level)-\(lit)"
        if let image = cache[key] { return image }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 62, height: 66)).image { _ in
            UIImage(named: lit ? "map-stone.png" : "map-stone-ahead.png")?.draw(in: CGRect(x: 0, y: 1, width: 62, height: 62))
            let disk = UIBezierPath(ovalIn: CGRect(x: 17, y: 25, width: 28, height: 20))
            (lit ? UIColor(red: 0.91, green: 0.70, blue: 0.36, alpha: 1) : UIColor(red: 0.24, green: 0.29, blue: 0.37, alpha: 1)).setFill(); disk.fill()
            (lit ? UIColor(red: 1, green: 0.90, blue: 0.63, alpha: 1) : UIColor(white: 0.70, alpha: 0.7)).setStroke(); disk.lineWidth = 1; disk.stroke()
            let style = NSMutableParagraphStyle(); style.alignment = .center
            let font = UIFont(name: "Nunito-ExtraBold", size: 13) ?? .boldSystemFont(ofSize: 13)
            ("\(level)" as NSString).draw(in: CGRect(x: 15, y: 26, width: 32, height: 20), withAttributes: [.font: font, .paragraphStyle: style,
                .foregroundColor: lit ? UIColor(red: 0.28, green: 0.18, blue: 0.10, alpha: 1) : UIColor(white: 0.92, alpha: 1)])
        }
        cache[key] = image; return image
    }
    static func plate(_ text: String, small: Bool) -> UIImage {
        let key = "plate-\(small)-\(text)"
        if let image = cache[key] { return image }
        let font = UIFont(name: small ? "Nunito" : "Fraunces", size: small ? 11.5 : 14) ?? (small ? .systemFont(ofSize: 11.5, weight: .semibold) : .systemFont(ofSize: 14, weight: .semibold))
        let width = min(205, max(45, ceil((text as NSString).size(withAttributes: [.font: font]).width) + 24))
        let size = CGSize(width: width, height: small ? 24 : 31)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            guard !text.isEmpty else { return }
            let rect = CGRect(x: 1, y: 1, width: width - 2, height: size.height - 4)
            let lip = UIBezierPath(roundedRect: rect.offsetBy(dx: 0, dy: 2), cornerRadius: small ? 10 : 9)
            UIColor(white: 0, alpha: 0.5).setFill(); lip.fill()
            let body = UIBezierPath(roundedRect: rect, cornerRadius: small ? 10 : 9)
            UIColor(red: 0.11, green: 0.10, blue: 0.15, alpha: small ? 0.82 : 0.95).setFill(); body.fill()
            UIColor(red: 0.85, green: 0.68, blue: 0.41, alpha: small ? 0.65 : 0.95).setStroke(); body.lineWidth = 0.8; body.stroke()
            let style = NSMutableParagraphStyle(); style.alignment = .center; style.lineBreakMode = .byTruncatingTail
            (text as NSString).draw(in: rect.insetBy(dx: 7, dy: small ? 3 : 4), withAttributes: [.font: font, .paragraphStyle: style,
                .foregroundColor: UIColor(red: 0.98, green: 0.92, blue: 0.80, alpha: 1)])
        }
        cache[key] = image; return image
    }
}
