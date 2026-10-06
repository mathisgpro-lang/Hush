// Embers that feel like money (decision 141): always on screen, they burst out of every finished quest and fly into
// the counter, which counts up coin by coin with a clink of haptics; a daily pouch for showing up; worlds bought
// with them on the map. Earned only by living, never sold (decision 81).
import SwiftUI

/// One Ember coin: Codex's painted coin when it's in the app, a painted-looking stand-in until then.
struct EmberCoin: View {
    var size: CGFloat = 18
    var body: some View {
        if let img = UIImage(named: "ember-coin.png") {
            Image(uiImage: img).resizable().scaledToFit().frame(width: size, height: size)
        } else {
            ZStack {
                Circle().fill(RadialGradient(colors: [Color(red: 1, green: 0.93, blue: 0.6), Theme.gold, Color(red: 0.78, green: 0.45, blue: 0.12)],
                                             center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.7))
                Circle().stroke(Color(red: 0.6, green: 0.32, blue: 0.08).opacity(0.8), lineWidth: max(1, size * 0.07))
                Image(systemName: "flame.fill").font(.system(size: size * 0.5, weight: .bold)).foregroundStyle(Color(red: 0.7, green: 0.3, blue: 0.05).opacity(0.85))
            }
            .frame(width: size, height: size)
            .shadow(color: .orange.opacity(0.5), radius: size * 0.2)
        }
    }
}

/// Where the counter sits on screen (in the window), so flying coins know where to land.
struct EmberTargetKey: PreferenceKey {
    static let defaultValue: CGPoint? = nil
    static func reduce(value: inout CGPoint?, nextValue: () -> CGPoint?) { value = nextValue() ?? value }
}

/// The counter: a coin and your total; it pops each time a coin lands.
struct EmbersBadge: View {
    let value: Int
    var body: some View {
        HStack(spacing: 5) {
            EmberCoin(size: 17)
                .background(GeometryReader { g in
                    Color.clear.preference(key: EmberTargetKey.self, value: CGPoint(x: g.frame(in: .global).midX, y: g.frame(in: .global).midY))
                })
            Text("\(value)").font(.num(15, .bold)).monospacedDigit().contentTransition(.numericText(value: Double(value)))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(.black.opacity(0.45)))
        .overlay(Capsule().stroke(Theme.gold.opacity(0.45), lineWidth: 1))
        .scaleEffect(1)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: value)
    }
}

/// A burst of coins flying from a point to the counter along arcs, one after another. Each landing calls `landed`.
struct CoinFlight: View {
    struct Burst: Equatable { let id = UUID(); let from: CGPoint; let to: CGPoint; let coins: Int; let start: Date }
    let burst: Burst
    let landed: (Int) -> Void
    let done: () -> Void
    @State private var landedCount = 0
    private static let flight = 0.75, gap = 0.07

    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince(burst.start)
            ZStack {
                ForEach(0..<burst.coins, id: \.self) { i in
                    let k = (t - Double(i) * Self.gap) / Self.flight
                    if k > 0 && k < 1 {
                        let e = k * k * (3 - 2 * k)
                        let spread = CGFloat((Double(i * 37 % 11) / 10 - 0.5) * 160)        // each coin its own arc
                        let mid = CGPoint(x: (burst.from.x + burst.to.x) / 2 + spread, y: min(burst.from.y, burst.to.y) - 60 - CGFloat(i % 3) * 25)
                        let x = (1 - e) * (1 - e) * burst.from.x + 2 * (1 - e) * e * mid.x + e * e * burst.to.x
                        let y = (1 - e) * (1 - e) * burst.from.y + 2 * (1 - e) * e * mid.y + e * e * burst.to.y
                        EmberCoin(size: 26 - CGFloat(e) * 10)
                            .rotation3DEffect(.degrees(k * 540 + Double(i) * 40), axis: (0, 1, 0))
                            .position(x: x, y: y)
                    }
                }
            }
            .onChange(of: Int((t - Self.flight) / Self.gap) + 1) { _, n in
                let now = max(0, min(burst.coins, n))
                if now > landedCount {
                    for c in landedCount..<now { landed(c) }
                    landedCount = now
                    if now == burst.coins { done() }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// The daily pouch: a small gift for showing up today; collecting it sends its coins to the counter.
struct DailyPouch: View {
    let amount: Int
    let collect: (CGPoint) -> Void
    @State private var bob = false
    var body: some View {
        GeometryReader { g in
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [Theme.gold.opacity(0.5), .clear], center: .center, startRadius: 2, endRadius: 70)).frame(width: 140, height: 140)
                    if let img = UIImage(named: "ember-pouch.png") {
                        Image(uiImage: img).resizable().scaledToFit().frame(width: 84, height: 84)
                    } else {
                        ZStack { EmberCoin(size: 44).offset(x: -16, y: 8); EmberCoin(size: 48).offset(x: 14, y: 4); EmberCoin(size: 52) }
                    }
                }
                .offset(y: bob ? -4 : 4)
                Text("A gift for showing up").font(.story(22)).foregroundStyle(Theme.ink)
                Text("Every day you come back, your Flame finds a few Embers.").font(.ui(13)).foregroundStyle(Theme.ink.opacity(0.65)).multilineTextAlignment(.center)
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    collect(CGPoint(x: g.frame(in: .global).midX, y: g.frame(in: .global).midY - 40))
                } label: {
                    HStack(spacing: 6) { Text("Collect").font(.ui(17, .bold)); EmberCoin(size: 18); Text("+\(amount)").font(.num(17, .heavy)) }
                        .padding(.horizontal, 30).padding(.vertical, 12)
                        .background(Capsule().fill(LinearGradient(colors: [Theme.gold, Color(red: 0.95, green: 0.55, blue: 0.25)], startPoint: .top, endPoint: .bottom)))
                        .foregroundStyle(Color(red: 0.25, green: 0.12, blue: 0.05))
                }
                .buttonStyle(PressableStyle())
            }
            .padding(22)
            .background(SheetPaper(corner: 24))
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black.opacity(0.35).ignoresSafeArea())
        .onAppear { withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { bob = true } }
    }
}

/// The top bar of every world (decision 146): one slim, quiet capsule. Your streak, the day of the arc, your Embers,
/// separated by hairlines; nothing shouts.
struct HUDBar: View {
    let journey: Journey
    let embers: Int
    var body: some View {
        let s = journey.streak(), lit = s.state == .livedToday
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(lit ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 0.88, blue: 0.55), Color(red: 1, green: 0.6, blue: 0.28)], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Theme.cream.opacity(0.5)))
                Text("\(s.current)").font(.num(14, .bold)).contentTransition(.numericText(value: Double(s.current)))
                if s.shields > 0 {
                    Image(systemName: "shield.fill").font(.system(size: 9)).foregroundStyle(Color(red: 0.7, green: 0.82, blue: 0.95).opacity(0.85))
                }
            }
            Rectangle().fill(Theme.cream.opacity(0.18)).frame(width: 0.5, height: 14)
            Text("Day \(min(journey.dayNumber(), Progression.arcLength)) / \(Progression.arcLength)").font(.ui(13, .semibold)).foregroundStyle(Theme.cream.opacity(0.85))
            Rectangle().fill(Theme.cream.opacity(0.18)).frame(width: 0.5, height: 14)
            HStack(spacing: 5) {
                EmberCoin(size: 15)
                    .background(GeometryReader { g in
                        Color.clear.preference(key: EmberTargetKey.self, value: CGPoint(x: g.frame(in: .global).midX, y: g.frame(in: .global).midY))
                    })
                Text("\(embers)").font(.num(14, .bold)).contentTransition(.numericText(value: Double(embers)))
            }
        }
        .foregroundStyle(Theme.cream)
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Capsule(style: .continuous).fill(.black.opacity(0.32)))
        .overlay(Capsule(style: .continuous).stroke(Theme.champagne.opacity(0.22), lineWidth: 0.5))
        .animation(Motion.soft, value: embers)
    }
}
