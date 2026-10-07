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

    @State private var friend: Friend?
    @State private var tab = 0                       // Character · Journey · Friends
    @Namespace private var tabLine

    // Your Flame, quiet (decision 147, Mathis: "laggy… you can see the edge… too much information… too much in your
    // face, should be more subtle, more minimalist"): one screen, no scrolling. Your Spark breathing at the centre,
    // five fine rings for what it will wear (the shop, later), three quiet numbers, and one small panel at a time.
    var body: some View {
        let _ = PerfProbe.body("FlameSheet")
        let l = Progression.level(xp: j.totalXP), s = j.streak()
        ZStack(alignment: .topTrailing) {
            LinearGradient(colors: [Color(red: 0.06, green: 0.04, blue: 0.035).opacity(0.9), Color(red: 0.09, green: 0.055, blue: 0.04).opacity(0.97)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .onTapGesture { }
            VStack(spacing: 0) {
                Spacer(minLength: 24)
                spark
                VStack(spacing: 4) {
                    Text(j.name.isEmpty ? "Your Spark" : "\(j.name)'s Spark").font(.story(26, .medium).italic()).foregroundStyle(Theme.cream)
                    Text("SPARK · DAY \(j.dayNumber())").font(.ui(11, .semibold)).tracking(2).foregroundStyle(Theme.champagne.opacity(0.8))
                }
                .padding(.top, 6)
                Spacer(minLength: 22)
                // Three quiet numbers.
                HStack(spacing: 0) {
                    figure("\(l.level)", "level")
                    Rectangle().fill(Theme.cream.opacity(0.15)).frame(width: 0.5, height: 34)
                    figure("\(s.current)", s.current == 1 ? "day in a row" : "days in a row")
                    Rectangle().fill(Theme.cream.opacity(0.15)).frame(width: 0.5, height: 34)
                    figure("\(j.embers)", "Embers")
                }
                // XP: one hairline, filling.
                VStack(spacing: 6) {
                    GeometryReader { g in
                        Capsule().fill(Theme.cream.opacity(0.12))
                        Capsule().fill(Theme.champagne.opacity(0.85)).frame(width: g.size.width * CGFloat(l.into) / CGFloat(max(1, l.span)))
                    }
                    .frame(height: 2)
                    Text("\(l.span - l.into) XP to level \(l.level + 1)").font(.story(13).italic()).foregroundStyle(Theme.cream.opacity(0.55))
                }
                .padding(.horizontal, 60).padding(.top, 14)
                Spacer(minLength: 22)
                tabsRow
                Group {
                    switch tab {
                    case 0: characterPanel
                    case 1: journeyPanel
                    default: FriendsStrip(friends: Friend.samples, onDark: true) { f in withAnimation(Motion.soft) { friend = f } }
                    }
                }
                .frame(height: 150)
                .padding(.horizontal, 24).padding(.top, 14)
                .transition(.opacity)
                .id(tab)
                Spacer(minLength: 18)
            }
            Button { close() } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.cream.opacity(0.8))
                    .frame(width: 34, height: 34).background(Circle().fill(.white.opacity(0.08)))
                    .overlay(Circle().stroke(Theme.champagne.opacity(0.2), lineWidth: 0.5))
            }
            .buttonStyle(PressableStyle())
            .padding(.trailing, 18).padding(.top, 6)
            if let f = friend { FriendProfile(friend: f) { withAnimation(Motion.soft) { friend = nil } }.transition(.move(edge: .bottom)) }
        }
        .onAppear {
            bob = true
            if CommandLine.arguments.contains("-friend") { friend = Friend.samples[0] }     // (test)
        }
    }

    /// Your Spark, breathing in its glow, ringed by five fine sockets (empty for now: the shop fills them later).
    private var spark: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [Color(red: 1, green: 0.6, blue: 0.25).opacity(0.35), .clear], center: .center, startRadius: 6, endRadius: 120))
                .frame(width: 240, height: 240).scaleEffect(bob ? 1.05 : 0.95)
            Circle().stroke(Theme.champagne.opacity(0.12), lineWidth: 0.5).frame(width: 210, height: 210)
            ForEach(0..<5, id: \.self) { i in
                let a = (Double(i) / 5) * 2 * .pi - .pi / 2
                Circle().stroke(Theme.champagne.opacity(0.35), lineWidth: 0.75).frame(width: 26, height: 26)
                    .background(Circle().fill(Color.black.opacity(0.25)))
                    .offset(x: cos(a) * 105, y: sin(a) * 105)
            }
            Image(uiImage: SparkTint.image("spark-keyed.png", ember: model.emberID) ?? UIImage()).resizable().scaledToFit()
                .frame(height: 120).offset(y: bob ? -4 : 3)
        }
        .frame(height: 240)
        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: bob)
    }

    private func figure(_ big: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(big).font(.num(26, .bold)).foregroundStyle(Theme.cream).monospacedDigit()
            Text(label).font(.story(13).italic()).foregroundStyle(Theme.cream.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    private var tabsRow: some View {
        HStack(spacing: 26) {
            ForEach(Array(["Character", "Journey", "Friends"].enumerated()), id: \.offset) { i, t in
                Button { withAnimation(Motion.soft) { tab = i } } label: {
                    VStack(spacing: 5) {
                        Text(t).font(.story(15, tab == i ? .medium : .regular)).foregroundStyle(Theme.cream.opacity(tab == i ? 1 : 0.45))
                        ZStack {
                            if tab == i { Capsule().fill(Theme.champagne).frame(height: 1.5).matchedGeometryEffect(id: "t", in: tabLine) }
                            else { Color.clear.frame(height: 1.5) }
                        }
                    }
                    .fixedSize()
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    /// Six emblems, each with its number (Day 1 → today in a quiet line under it).
    private var characterPanel: some View {
        HStack(spacing: 0) {
            ForEach(Pillar6.allCases, id: \.self) { p in
                let v = j.attribute(p)
                VStack(spacing: 5) {
                    Image(uiImage: UIImage(named: "pillar-\(p.rawValue.lowercased()).png") ?? UIImage()).resizable().scaledToFit()
                        .frame(width: 40, height: 40).opacity(v > 0 ? 1 : 0.55)
                    Text("\(v)").font(.num(16, .bold)).foregroundStyle(Theme.cream.opacity(v > 0 ? 1 : 0.45)).monospacedDigit()
                    Text(p.attribute).font(.story(10).italic()).foregroundStyle(Theme.cream.opacity(0.5)).lineLimit(1).minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// This week's seven flames, and the 66-day line.
    private var journeyPanel: some View {
        let d = min(j.dayNumber(), Progression.arcLength)
        return VStack(spacing: 18) {
            HStack(spacing: 0) {
                ForEach(Array(zip(["M", "T", "W", "T", "F", "S", "S"], j.thisWeek).enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 5) {
                        Image(systemName: "flame.fill").font(.system(size: 16))
                            .foregroundStyle(day.1 ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 0.88, blue: 0.55), Color(red: 1, green: 0.6, blue: 0.28)], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Theme.cream.opacity(0.15)))
                        Text(day.0).font(.ui(10, .semibold)).foregroundStyle(Theme.cream.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            VStack(spacing: 6) {
                GeometryReader { g in
                    Capsule().fill(Theme.cream.opacity(0.12))
                    Capsule().fill(Theme.champagne.opacity(0.85)).frame(width: g.size.width * CGFloat(d) / CGFloat(Progression.arcLength))
                }
                .frame(height: 2)
                Text(d >= Progression.arcLength ? "You graduated. A new arc begins." : "Day \(d) of \(Progression.arcLength) · at 66 days, your habits become you")
                    .font(.story(13).italic()).foregroundStyle(Theme.cream.opacity(0.55)).multilineTextAlignment(.center)
            }
        }
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
                    if let d = j.dayOne[p.rawValue] {                 // where you stood on Day 1 (the introduction)
                        Text("Day 1: \(["low", "okay", "good"][max(0, min(2, d))])").font(.ui(11)).foregroundStyle(cream.opacity(0.45))
                    } else {
                        Text("0 →").font(.num(12)).foregroundStyle(cream.opacity(0.35))
                    }
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
            .background(SheetPaper(corner: 18))
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

/// A ribbon tab: a banner with notched ends.
nonisolated struct RibbonShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(); let n: CGFloat = 8
        p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - n, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY)); p.addLine(to: CGPoint(x: r.minX + n, y: r.midY)); p.closeSubpath()
        return p
    }
}
