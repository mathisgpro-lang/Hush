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
    private static let sockets: [(String, CGFloat, CGFloat)] = [("Crown", 0.501, 0.097), ("Aura", 0.342, 0.221), ("Cloak", 0.660, 0.221),
                                                                ("Trinket", 0.288, 0.51), ("Companion", 0.718, 0.51)]
    private let wood = Color(red: 0.13, green: 0.08, blue: 0.05)

    // A fantasy character sheet (decision 143, Mathis: "like a Witcher inventory"): Codex's carved frame fills the
    // screen, your Spark alive on the hearth, five equipment sockets (filled from the shop, later), your level and
    // streak on the two parchment panels; below, ribbon tabs: your character, your journey, your friends.
    var body: some View {
        let _ = PerfProbe.body("FlameSheet")
        GeometryReader { g in
            let w = g.size.width, heroH = w * 1730 / 909
            ZStack(alignment: .topTrailing) {
                wood.ignoresSafeArea()
                ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 0).id("top")
                        hero(w: w, h: heroH)
                        ribbons.padding(.top, -18)
                        Group {
                            switch tab {
                            case 0: characterTab
                            case 1: journeyTab
                            default: card { FriendsStrip(friends: Friend.samples) { f in withAnimation(.sheet) { friend = f } } }
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 12)
                        Spacer().frame(height: 40).id("bottom")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .perfScroll)) { n in
                    withAnimation(.easeInOut(duration: 1.2)) { proxy.scrollTo(n.object as? String ?? "top") }
                }
                }
                .ignoresSafeArea(edges: .top)
                Button { close() } label: {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.cream)
                        .frame(width: 36, height: 36).background(Circle().fill(.black.opacity(0.5)))
                        .overlay(Circle().stroke(Theme.gold.opacity(0.5), lineWidth: 1))
                }
                .padding(.trailing, 16).padding(.top, 4)
                if let f = friend { FriendProfile(friend: f) { withAnimation(.sheet) { friend = nil } }.transition(.move(edge: .bottom)) }
            }
        }
        .onAppear {
            bob = true
            if CommandLine.arguments.contains("-friend") { friend = Friend.samples[0] }     // (test)
        }
    }

    // MARK: The hero: the frame, your Spark on the hearth, the sockets, the two parchment panels

    private func hero(w: CGFloat, h: CGFloat) -> some View {
        let l = Progression.level(xp: j.totalXP), s = j.streak()
        return ZStack(alignment: .topLeading) {
            Image(uiImage: UIImage(named: "sheet-frame.jpg") ?? UIImage()).resizable().frame(width: w, height: h)
            // Your Spark, alive on the hearth (breathing, its glow pulsing).
            ZStack {
                Circle().fill(RadialGradient(colors: [Color.orange.opacity(0.55), .clear], center: .center, startRadius: 4, endRadius: w * 0.26))
                    .frame(width: w * 0.52, height: w * 0.52).scaleEffect(bob ? 1.06 : 0.94)
                Image(uiImage: SparkTint.image("spark-keyed.png", ember: model.emberID) ?? UIImage()).resizable().scaledToFit()
                    .frame(height: w * 0.3).offset(y: bob ? -5 : 3)
            }
            .animation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true), value: bob)
            .position(x: w * 0.5, y: h * 0.6)
            // Name and stage on a banner over the carpet.
            VStack(spacing: 1) {
                Text(j.name.isEmpty ? "Your Spark" : "\(j.name)'s Spark").font(.story(24, .semibold)).foregroundStyle(Theme.cream)
                Text("Spark · day \(j.dayNumber())").font(.ui(13, .semibold)).foregroundStyle(Theme.gold)
            }
            .padding(.horizontal, 18).padding(.vertical, 6)
            .background(Capsule().fill(.black.opacity(0.45)))
            .position(x: w * 0.5, y: h * 0.84)
            // The sockets: locked until the shop.
            ForEach(Self.sockets, id: \.0) { name, x, y in
                VStack(spacing: 2) {
                    Image(systemName: "lock.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.gold.opacity(0.75))
                    Text(name).font(.ui(9, .bold)).foregroundStyle(Theme.cream.opacity(0.75))
                }
                .position(x: w * x, y: h * y)
            }
            // Left parchment: your level.
            VStack(spacing: 6) {
                Text("LEVEL").font(.ui(10, .heavy)).tracking(1.5).foregroundStyle(Theme.ink.opacity(0.7))
                ZStack {
                    Image(uiImage: UIImage(named: "wax-seal.png") ?? UIImage()).resizable().scaledToFit().frame(width: w * 0.17)
                    Text("\(l.level)").font(.num(24, .heavy)).foregroundStyle(Theme.cream).shadow(color: .black.opacity(0.4), radius: 2)
                }
                Text("\(j.totalXP)").font(.num(20, .heavy)).foregroundStyle(Theme.ink)
                Text("XP").font(.ui(10, .bold)).foregroundStyle(Theme.ink.opacity(0.6))
                Capsule().fill(Theme.ink.opacity(0.15)).frame(width: w * 0.16, height: 5)
                    .overlay(alignment: .leading) { Capsule().fill(Theme.accent).frame(width: w * 0.16 * CGFloat(l.into) / CGFloat(max(1, l.span)), height: 5) }
                Text("\(l.span - l.into) to \(l.level + 1)").font(.ui(10)).foregroundStyle(Theme.ink.opacity(0.6))
                Text("Day \(min(j.dayNumber(), Progression.arcLength)) of \(Progression.arcLength)").font(.ui(11, .bold)).foregroundStyle(Theme.accent).padding(.top, 4)
            }
            .frame(width: w * 0.22)
            .position(x: w * 0.148, y: h * 0.29)
            // Right parchment: your streak and your Embers.
            VStack(spacing: 6) {
                Image(systemName: "flame.fill").font(.system(size: 26)).foregroundStyle(LinearGradient(colors: [Color(red: 1, green: 0.85, blue: 0.4), .orange], startPoint: .top, endPoint: .bottom))
                Text("\(s.current)").font(.num(28, .heavy)).foregroundStyle(Theme.ink)
                Text("days in a row").font(.ui(10, .bold)).foregroundStyle(Theme.ink.opacity(0.65)).multilineTextAlignment(.center)
                HStack(spacing: 2) {
                    ForEach(0..<2, id: \.self) { i in Image(systemName: i < s.shields ? "shield.fill" : "shield").font(.system(size: 11)) }
                }
                .foregroundStyle(Color(red: 0.25, green: 0.45, blue: 0.7))
                Text("best \(s.best)").font(.ui(10)).foregroundStyle(Theme.ink.opacity(0.6))
                EmberCoin(size: 24).padding(.top, 6)
                Text("\(j.embers)").font(.num(18, .heavy)).foregroundStyle(Theme.ink)
                Text("Embers").font(.ui(10, .bold)).foregroundStyle(Theme.ink.opacity(0.6))
            }
            .frame(width: w * 0.22)
            .position(x: w * 0.852, y: h * 0.29)
        }
        .frame(width: w, height: h)
    }

    // MARK: Ribbons and tabs

    private var ribbons: some View {
        HStack(spacing: 8) {
            ForEach(Array(["Character", "Journey", "Friends"].enumerated()), id: \.offset) { i, t in
                Button { withAnimation(.spring(duration: 0.3)) { tab = i } } label: {
                    Text(t).font(.story(15, .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(RibbonShape().fill(tab == i ? LinearGradient(colors: [Color(red: 0.42, green: 0.14, blue: 0.11), Color(red: 0.3, green: 0.09, blue: 0.08)], startPoint: .top, endPoint: .bottom)
                                                        : LinearGradient(colors: [Color(red: 0.22, green: 0.15, blue: 0.11), Color(red: 0.16, green: 0.11, blue: 0.08)], startPoint: .top, endPoint: .bottom)))
                        .overlay(RibbonShape().stroke(Theme.champagne.opacity(tab == i ? 0.5 : 0.18), lineWidth: 0.6))
                        .foregroundStyle(Theme.cream.opacity(tab == i ? 1 : 0.7))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    private var characterTab: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Pillar6.allCases, id: \.self) { p in
                    let v = j.attribute(p)
                    VStack(spacing: 4) {
                        Image(uiImage: UIImage(named: "pillar-\(p.rawValue.lowercased()).png") ?? UIImage()).resizable().scaledToFit().frame(width: 58, height: 58)
                        Text(p.attribute.uppercased()).font(.ui(10, .heavy)).tracking(1.2).foregroundStyle(Theme.ink.opacity(0.8))
                        Text("\(v)").font(.num(24, .heavy)).foregroundStyle(v > 0 ? Theme.ink : Theme.ink.opacity(0.35)).monospacedDigit()
                        if let d = j.dayOne[p.rawValue] {
                            Text("Day 1: \(["low", "okay", "good"][max(0, min(2, d))])").font(.ui(9)).foregroundStyle(Theme.ink.opacity(0.5))
                        }
                    }
                    .padding(.vertical, 10).frame(maxWidth: .infinity).paperCard(14)
                }
            }
            .padding(14).background(SheetPaper(corner: 20))
            card { stat("\(j.daysLived)", "days lived", "Every day you live counts, forever.") }
        }
    }

    private var journeyTab: some View {
        VStack(spacing: 12) {
            card { week }
            card { arcCard }
            card { stageStrip }
            card {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles").foregroundStyle(gold)
                    Text(nextLine).font(.ui(15)).foregroundStyle(cream)
                    Spacer()
                }
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
