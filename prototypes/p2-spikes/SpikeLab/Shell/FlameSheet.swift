// Your Flame (decision 128): where you are in your journey. Your Spark, large and alive in your ember's color; its
// stage and the ones to come; this week's seven little flames (missed days are simply unlit, a fresh week every
// Monday); the days you've lived (it only grows); your six lights; how bright you've been lately; what's next.
// Decision 134: the streak at the core (protected: shields, repair, never touching what you've built), a level with
// its XP bar, and six attributes whose numbers climb, compared with Day 1.
import SwiftUI

struct FlameSheet: View {
    let model: ShellModel
    @Binding var isOpen: Bool
    @State private var bob = false
    private let cream = Theme.ink              // on parchment, like the Satchel and the Book
    private let gold = Theme.accent
    private static let stages = ["stage-spark", "stage-flame", "stage-blaze", "stage-kindled", "stage-beyond"]
    private static let stageNames = ["Spark", "Flame", "Blaze", "Kindled", "Beyond"]
    private static let lights: [(RealmID, String)] = [(.grove, "Heart"), (.library, "Mind"), (.highlands, "Body"),
                                                       (.stillwater, "Spirit"), (.forge, "Craft"), (.wilds, "World")]
    private var j: Journey { model.journey }

    var body: some View {
        let _ = PerfProbe.body("FlameSheet")
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { close() }
            ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Color.clear.frame(height: 0).id("top")
                    Capsule().fill(cream.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 10)
                    // Your Spark, alive.
                    // A painted glow behind it (no live shadow: shadows redraw on every frame and slow scrolling).
                    ZStack {
                        Circle().fill(RadialGradient(colors: [Color.orange.opacity(0.45), .clear], center: .center, startRadius: 4, endRadius: 80))
                            .frame(width: 170, height: 170)
                        Image(uiImage: SparkTint.image("spark-keyed.png", ember: model.emberID) ?? UIImage()).resizable().scaledToFit()
                            .frame(height: 120)
                            .offset(y: bob ? -5 : 3)
                            .animation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true), value: bob)
                    }
                    .frame(height: 140)
                    VStack(spacing: 2) {
                        Text(j.name.isEmpty ? "Your Spark" : "\(j.name)'s Spark").font(.story(26)).foregroundStyle(cream)
                        Text("Spark · day \(j.dayNumber())").font(.ui(14)).foregroundStyle(gold)
                    }
                    // Everything below is static while you scroll: drawn once into a single layer (it was being
                    // redrawn every frame with the Spark's breathing above it: 30–39 fps while scrolling).
                    VStack(spacing: 18) {
                    stageStrip
                    card { levelCard }
                    HStack(spacing: 12) {
                        card { streakCard }
                        card { stat("\(j.daysLived)", "days lived", "Every day you live counts, forever.") }
                    }
                    card { week }
                    card { attributes }
                    card { arcCard }
                    card {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles").foregroundStyle(gold)
                            Text(nextLine).font(.ui(15)).foregroundStyle(cream)
                            Spacer()
                        }
                    }
                    }
                    .drawingGroup()
                    Spacer().frame(height: 10).id("bottom")
                }
                .padding(.horizontal, 18)
            }
            .onReceive(NotificationCenter.default.publisher(for: .perfScroll)) { n in
                withAnimation(.easeInOut(duration: 1.2)) { proxy.scrollTo(n.object as? String ?? "top") }
            }
            }
            .frame(maxHeight: 680)
            .background(SheetPaper())
            .padding(.horizontal, 10).padding(.bottom, 8)
        }
        .onAppear { bob = true }
    }

    private var stageStrip: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(0..<5, id: \.self) { i in
                VStack(spacing: 4) {
                    Image(uiImage: SparkTint.image("\(Self.stages[i]).png", ember: model.emberID) ?? UIImage()).resizable().scaledToFit()
                        .frame(height: CGFloat(30 + i * 7))
                        .colorMultiply(i == 0 ? .white : .black).opacity(i == 0 ? 1 : 0.55)      // the next ones: silhouettes
                    Text(i == 4 ? "?" : Self.stageNames[i]).font(.ui(10)).foregroundStyle(cream.opacity(i == 0 ? 1 : 0.45))
                }
            }
        }
    }

    private var levelCard: some View {
        let l = Progression.level(xp: j.totalXP)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline) {
                VStack(spacing: 0) {
                    Text("\(l.level)").font(.num(34, .heavy)).foregroundStyle(Color(red: 0.25, green: 0.12, blue: 0.05))
                    Text("LEVEL").font(.ui(9, .heavy)).foregroundStyle(Color(red: 0.25, green: 0.12, blue: 0.05).opacity(0.8))
                }
                .frame(width: 70, height: 64).background(RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: [Theme.gold, Color(red: 0.93, green: 0.5, blue: 0.2)], startPoint: .top, endPoint: .bottom)))
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(j.totalXP.formatted()).font(.num(28, .bold)).foregroundStyle(cream).monospacedDigit()
                    Text("XP earned").font(.ui(11)).foregroundStyle(cream.opacity(0.6))
                }
            }
            HStack(spacing: 3) {
                ForEach(0..<24, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2).fill(Double(i) < Double(24 * l.into) / Double(max(1, l.span)) ? Color.orange : cream.opacity(0.12)).frame(height: 9)
                }
            }
            Text("\(l.span - l.into) XP to level \(l.level + 1)").font(.ui(12)).foregroundStyle(cream.opacity(0.6)).frame(maxWidth: .infinity)
        }
    }

    private var streakCard: some View {
        let s = j.streak()
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("\(s.current)").font(.story(30)).foregroundStyle(gold)
            }
            Text("days in a row").font(.ui(13, .bold)).foregroundStyle(cream)
            HStack(spacing: 3) {
                ForEach(0..<2, id: \.self) { i in Image(systemName: i < s.shields ? "shield.fill" : "shield").font(.system(size: 11)) }
                Text("best \(s.best)").font(.ui(11)).padding(.leading, 4)
            }
            .foregroundStyle(Color(red: 0.25, green: 0.45, blue: 0.7))
        }
    }

    /// Six attributes, big numbers that climb, compared with Day 1 (Life Reset's "Your Rating", in our pillars).
    private var attributes: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your rating").font(.ui(15, .bold)).foregroundStyle(cream)
                Spacer()
                Text("Day 1 → today").font(.ui(11)).foregroundStyle(cream.opacity(0.5))
            }
            ForEach(Pillar6.allCases, id: \.self) { p in
                let v = j.attribute(p)
                HStack(spacing: 10) {
                    Image(systemName: p.realm.symbol).foregroundStyle(p.realm.color).frame(width: 22)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(p.attribute.uppercased()).font(.ui(12, .bold)).tracking(1.5).foregroundStyle(cream.opacity(0.85))
                        Text("\(p.rawValue) · \(p.realm.name)").font(.ui(10)).foregroundStyle(cream.opacity(0.4))
                    }
                    Spacer()
                    Text("0 →").font(.num(12)).foregroundStyle(cream.opacity(0.35))
                    if v > 0 { Image(systemName: "arrowtriangle.up.fill").font(.system(size: 9)).foregroundStyle(Color(red: 0.25, green: 0.6, blue: 0.3)) }
                    Text("\(v)").font(.num(28, .bold)).monospacedDigit().foregroundStyle(v > 0 ? cream : cream.opacity(0.3))
                }
            }
        }
    }

    private var arcCard: some View {
        let d = min(j.dayNumber(), Progression.arcLength)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("The first arc").font(.ui(15, .bold)).foregroundStyle(cream)
                Spacer()
                Text("Day \(d) / \(Progression.arcLength)").font(.ui(13, .bold)).foregroundStyle(gold)
            }
            GeometryReader { g in
                Capsule().fill(cream.opacity(0.12))
                Capsule().fill(LinearGradient(colors: [Theme.gold, .orange], startPoint: .leading, endPoint: .trailing)).frame(width: g.size.width * CGFloat(d) / CGFloat(Progression.arcLength))
            }
            .frame(height: 8)
            Text(d >= Progression.arcLength ? "You graduated. A new arc begins." : "At day 66, your Spark graduates: the habits you built become part of who you are.")
                .font(.ui(12)).foregroundStyle(cream.opacity(0.6))
        }
    }

    private var week: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This week").font(.ui(15, .bold)).foregroundStyle(cream)
            HStack {
                ForEach(Array(zip(["M", "T", "W", "T", "F", "S", "S"], j.thisWeek).enumerated()), id: \.offset) { _, d in
                    VStack(spacing: 4) {
                        Image(systemName: "flame.fill").font(.system(size: 20))
                            .foregroundStyle(d.1 ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 0.9, blue: 0.5), .orange], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(cream.opacity(0.15)))

                        Text(d.0).font(.ui(11)).foregroundStyle(cream.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            Text("A fresh week begins every Monday.").font(.ui(12)).foregroundStyle(cream.opacity(0.5))
        }
    }

    private var sixLights: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your six lights").font(.ui(15, .bold)).foregroundStyle(cream)
            ForEach(Self.lights, id: \.1) { realm, pillar in
                let n = j.light(for: realm), level = n / 3 + 1, part = CGFloat(n % 3) / 3
                HStack(spacing: 10) {
                    Image(systemName: realm.symbol).foregroundStyle(realm.color).frame(width: 22)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(pillar).font(.ui(14)).foregroundStyle(cream)
                            Text("· \(realm.name)").font(.ui(11)).foregroundStyle(cream.opacity(0.45))
                            Spacer()
                            Text(n == 0 ? "not lit yet" : "level \(level)").font(.ui(11)).foregroundStyle(n == 0 ? cream.opacity(0.4) : realm.color)
                        }
                        Capsule().fill(cream.opacity(0.1)).frame(height: 5)
                            .overlay(alignment: .leading) { GeometryReader { g in
                                Capsule().fill(realm.color).frame(width: g.size.width * max(n == 0 ? 0 : 0.08, part))
                            } }
                    }
                }
            }
        }
    }

    private func card<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        c().padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .paperCard()
    }

    private func stat(_ big: String, _ label: String, _ line: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(big).font(.story(30)).foregroundStyle(gold)
            Text(label).font(.ui(13, .bold)).foregroundStyle(cream)
            Text(line).font(.ui(11)).foregroundStyle(cream.opacity(0.55)).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var vitalityLine: String {
        switch j.lastSeven {
        case 5...: "You're burning bright."
        case 3...4: "A steady glow."
        case 1...2: "A small, warm glow."
        default: "Resting. One small thing relights me."
        }
    }

    private var nextLine: String {
        let d = j.dayNumber()
        if d < 7 { return d == 6 ? "Tomorrow, I'll want a name." : "In \(7 - d) days, I'll want a name." }
        return "I'll grow as your lights grow."
    }

    private func close() { withAnimation(.sheet) { isOpen = false } }
}
