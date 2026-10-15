// The XP moment (Mathis, 2026-10-15: "super gamified and satisfying, minimalist though… so that the user really wants
// to keep grinding"). After every quest a small card drops in from the top: the quest's skill bar fills with a tick of
// haptic as it goes, bursts and rolls over at a level-up; your Flame's bar fills below it; then it slips away.
// A new Flame level opens the full LevelUpScreen (after his reference: a badge, "LEVEL UP!", the bar, what you earned,
// Collect). Everything here is drawn without blurred shadows (decision 165: 60 fps over the moving world).
import SwiftUI

typealias LevelSpan = (level: Int, into: Int, span: Int)
private func fraction(_ l: LevelSpan) -> CGFloat { CGFloat(l.into) / CGFloat(max(1, l.span)) }

/// One bar's state while it animates.
struct BarRun: Equatable { var level: Int; var fill: CGFloat }

enum XPHaptics {
    static let selection = UISelectionFeedbackGenerator()
    /// Light ticks while a bar fills (you feel it climb).
    static func fill(ticks: Int, over seconds: Double) {
        Task { @MainActor in
            selection.prepare()
            for _ in 0..<ticks { selection.selectionChanged(); try? await Task.sleep(for: .seconds(seconds / Double(ticks))) }
        }
    }
    static func levelUp() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

// MARK: - Pieces

/// A soft star badge (the reference's burst, in our gold).
nonisolated struct StarBurst: Shape {
    var points = 10
    var inner: CGFloat = 0.8
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY), R = min(r.width, r.height) / 2
        for i in 0..<(points * 2) {
            let a = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let rad = i.isMultiple(of: 2) ? R : R * inner
            let pt = CGPoint(x: c.x + cos(a) * rad, y: c.y + sin(a) * rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

private struct Spark { var d: CGFloat = 0; var o: Double = 0; var s: CGFloat = 1 }

/// Little sparks flying out of a point each time `trigger` changes.
struct SparkBurst: View {
    let trigger: Int
    var color: Color = Theme.champagne
    var radius: CGFloat = 36
    var count = 8
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let a = Double(i) / Double(count) * 2 * .pi + 0.3
                Circle().fill(color).frame(width: 5, height: 5)
                    .keyframeAnimator(initialValue: Spark(), trigger: trigger) { v, s in
                        v.scaleEffect(s.s).offset(x: cos(a) * s.d, y: sin(a) * s.d).opacity(s.o)
                    } keyframes: { _ in
                        KeyframeTrack(\.d) { CubicKeyframe(0, duration: 0.01); CubicKeyframe(radius, duration: 0.5) }
                        KeyframeTrack(\.o) { CubicKeyframe(1, duration: 0.01); CubicKeyframe(1, duration: 0.22); CubicKeyframe(0, duration: 0.33) }
                        KeyframeTrack(\.s) { CubicKeyframe(1.3, duration: 0.01); CubicKeyframe(0.3, duration: 0.55) }
                    }
            }
        }
        .allowsHitTesting(false)
    }
}

/// A glossy bar: its fill, a light sweeping along it, and a white flash on a level-up.
struct XPBar: View {
    let fill: CGFloat
    var height: CGFloat = 8
    var colors: [Color] = [Theme.champagne, Theme.gold]
    var flash = 0
    @State private var sweep = false
    var body: some View {
        GeometryReader { g in
            let w = max(fill > 0.001 ? height : 0, g.size.width * min(1, max(0, fill)))
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.13))
                Capsule().fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                    .overlay(alignment: .top) {                       // a little gloss on top
                        Capsule().fill(.white.opacity(0.38)).frame(height: max(1.5, height * 0.3))
                            .padding(.horizontal, height * 0.45).padding(.top, height * 0.14)
                    }
                    .overlay(alignment: .leading) {                   // light running along the filled part
                        LinearGradient(colors: [.clear, .white.opacity(0.6), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 34).offset(x: sweep ? w + 10 : -44)
                    }
                    .clipShape(Capsule())
                    .frame(width: w)
                Capsule().fill(.white)
                    .keyframeAnimator(initialValue: 0.0, trigger: flash) { v, o in v.opacity(o) } keyframes: { _ in
                        KeyframeTrack { CubicKeyframe(0.95, duration: 0.06); CubicKeyframe(0, duration: 0.45) }
                    }
            }
        }
        .frame(height: height)
        .onAppear { withAnimation(.linear(duration: 1.5).delay(0.4).repeatForever(autoreverses: false)) { sweep = true } }
    }
}

/// A level number on a gold star; it pops (with sparks) each time `pop` changes.
struct LevelBadge: View {
    let level: Int
    let pop: Int
    var size: CGFloat = 34
    var colors: [Color] = [Color(red: 1, green: 0.93, blue: 0.7), Theme.gold]
    var body: some View {
        ZStack {
            StarBurst(points: 10, inner: 0.84).fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            StarBurst(points: 10, inner: 0.84).stroke(.white.opacity(0.7), lineWidth: 1)
            Text("\(level)").font(.num(size * 0.42, .heavy)).foregroundStyle(Theme.ink)
                .contentTransition(.numericText(value: Double(level)))
            SparkBurst(trigger: pop, radius: size * 1.15)
        }
        .frame(width: size, height: size)
        .keyframeAnimator(initialValue: CGFloat(1), trigger: pop) { v, s in v.scaleEffect(s) } keyframes: { _ in
            KeyframeTrack { SpringKeyframe(1.6, duration: 0.18, spring: .snappy); SpringKeyframe(1, duration: 0.5, spring: .bouncy) }
        }
    }
}

// MARK: - The card after every quest

struct XPGainCard: View {
    let outcome: DeedOutcome
    let done: () -> Void
    @State private var shown = false
    @State private var skill = BarRun(level: 1, fill: 0)
    @State private var flame = BarRun(level: 1, fill: 0)
    @State private var xpShown = 0
    @State private var skillPop = 0
    @State private var flamePop = 0
    @State private var skillLeveled = false
    @State private var flameLeveled = false
    @State private var finished = false

    private var tint: Color { outcome.pillar.realm.color }

    var body: some View {
        VStack {
            VStack(spacing: 12) {
                row(icon: Image(uiImage: UIImage(named: "pillar-\(outcome.pillar.rawValue.lowercased()).png") ?? UIImage()),
                    name: outcome.pillar.attribute, leveled: skillLeveled, run: skill, pop: skillPop, barHeight: 10,
                    colors: [tint.opacity(0.75), tint], trailing: "+\(xpShown) XP")
                Rectangle().fill(Theme.cream.opacity(0.1)).frame(height: 0.5)
                row(icon: Image(uiImage: UIImage(named: PixelMode.world ? "px-icon-flame.png" : "icon-flame-v2.png") ?? UIImage()),
                    name: "Your Flame", leveled: flameLeveled, run: flame, pop: flamePop, barHeight: 6,
                    colors: [Theme.champagne, Theme.gold], trailing: nil)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.floor.opacity(0.94)))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.champagne.opacity(0.32), lineWidth: 0.75))
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.black.opacity(0.3)).offset(y: 4))
            .padding(.horizontal, 16)
            .offset(y: shown ? 0 : -190)
            .opacity(shown ? 1 : 0)
            .onTapGesture { dismiss() }
            Spacer()
        }
        .padding(.top, 6)
        .onAppear(perform: run)
    }

    private func row(icon: Image, name: String, leveled: Bool, run: BarRun, pop: Int, barHeight: CGFloat,
                     colors: [Color], trailing: String?) -> some View {
        HStack(spacing: 12) {
            icon.resizable().interpolation(.none).scaledToFit().frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(name).font(.story(16, .medium)).foregroundStyle(Theme.cream)
                    if leveled {
                        Text("LEVEL UP").font(.ui(10, .heavy)).tracking(1.2).foregroundStyle(Theme.ink)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(Theme.gold))
                            .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }
                    Spacer(minLength: 0)
                    if let trailing {
                        Text(trailing).font(.num(15, .bold)).foregroundStyle(Theme.champagne).monospacedDigit()
                            .contentTransition(.numericText(value: Double(xpShown)))
                    }
                }
                XPBar(fill: run.fill, height: barHeight, colors: colors, flash: pop)
            }
            LevelBadge(level: run.level, pop: pop, size: barHeight > 8 ? 36 : 30)
        }
    }

    private func run() {
        let sb = Progression.skill(xp: outcome.attributeBefore), sa = Progression.skill(xp: outcome.attributeAfter)
        let fb = Progression.level(xp: outcome.totalXPBefore), fa = Progression.level(xp: outcome.totalXPAfter)
        skill = BarRun(level: sb.level, fill: fraction(sb))
        flame = BarRun(level: fb.level, fill: fraction(fb))
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { shown = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(330))
            withAnimation(.easeOut(duration: 0.6)) { xpShown = outcome.xp }
            await fill(from: sb, to: sa, set: { skill = $0 }) {
                skillPop += 1
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { skillLeveled = true }
            }
            try? await Task.sleep(for: .milliseconds(140))
            await fill(from: fb, to: fa, set: { flame = $0 }) {
                flamePop += 1
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { flameLeveled = true }
            }
            // A new Flame level hands over quickly to its full screen; otherwise the card lingers a moment.
            try? await Task.sleep(for: .milliseconds(fa.level > fb.level ? 650 : 1400))
            dismiss()
        }
    }

    /// Fills a bar from one level-state to another; at a level-up it fills to the end, bursts, rolls over and goes on.
    private func fill(from b: LevelSpan, to a: LevelSpan, set: @escaping (BarRun) -> Void, levelUp: @escaping () -> Void) async {
        if a.level > b.level {
            XPHaptics.fill(ticks: 6, over: 0.45)
            withAnimation(.easeIn(duration: 0.45)) { set(BarRun(level: b.level, fill: 1)) }
            try? await Task.sleep(for: .milliseconds(470))
            XPHaptics.levelUp()
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) { set(BarRun(level: b.level, fill: 0)) }       // rolls over
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { set(BarRun(level: a.level, fill: 0)) }
            levelUp()
            try? await Task.sleep(for: .milliseconds(220))
            XPHaptics.fill(ticks: 4, over: 0.5)
            withAnimation(.easeOut(duration: 0.5)) { set(BarRun(level: a.level, fill: fraction(a))) }
            try? await Task.sleep(for: .milliseconds(520))
        } else {
            XPHaptics.fill(ticks: 6, over: 0.7)
            withAnimation(.easeOut(duration: 0.7)) { set(BarRun(level: a.level, fill: fraction(a))) }
            try? await Task.sleep(for: .milliseconds(720))
        }
    }

    private func dismiss() {
        guard !finished else { return }
        finished = true
        withAnimation(.easeIn(duration: 0.28)) { shown = false }
        Task { @MainActor in try? await Task.sleep(for: .milliseconds(300)); done() }
    }
}

// MARK: - The Flame's level-up, full screen

struct LevelUpScreen: View {
    let outcome: DeedOutcome
    let journey: Journey
    /// Collect: the bonus is granted and its coins fly from this point to the counter.
    let collect: (CGPoint) -> Void
    @State private var badgeIn = false
    @State private var titleIn = false
    @State private var barFill: CGFloat = 0
    @State private var rowsIn = 0
    @State private var pop = 0
    @State private var twinkle = false
    @State private var collected = false

    private var level: Int { outcome.levelAfter }
    private var bonus: Int { Progression.levelBonus(level) }

    var body: some View {
        let l = Progression.level(xp: outcome.totalXPAfter)
        let skillBefore = Progression.skill(xp: outcome.attributeBefore).level, skillAfter = Progression.skill(xp: outcome.attributeAfter).level
        ZStack {
            Theme.floor.ignoresSafeArea()
            RadialGradient(colors: [Theme.gold.opacity(0.28), .clear], center: .init(x: 0.5, y: 0.2), startRadius: 10, endRadius: 320)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                // The badge: a big gold star with the level, sparks twinkling around it.
                ZStack {
                    ForEach(0..<6, id: \.self) { i in
                        let a = Double(i) / 6 * 2 * .pi + 0.4, r: CGFloat = i.isMultiple(of: 2) ? 92 : 78
                        Image(systemName: "sparkle").font(.system(size: i.isMultiple(of: 2) ? 14 : 10, weight: .bold))
                            .foregroundStyle(Theme.champagne)
                            .offset(x: cos(a) * r, y: sin(a) * r)
                            .opacity(badgeIn ? (twinkle == i.isMultiple(of: 2) ? 1 : 0.35) : 0)
                            .scaleEffect(twinkle == i.isMultiple(of: 2) ? 1.15 : 0.8)
                    }
                    StarBurst(points: 12, inner: 0.82)
                        .fill(LinearGradient(colors: [Color(red: 1, green: 0.95, blue: 0.78), Theme.gold, Color(red: 0.9, green: 0.55, blue: 0.2)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 150, height: 150)
                    StarBurst(points: 12, inner: 0.82).stroke(.white.opacity(0.8), lineWidth: 1.5).frame(width: 150, height: 150)
                    StarBurst(points: 12, inner: 0.82).fill(.white.opacity(0.18)).frame(width: 118, height: 118)
                    VStack(spacing: -4) {
                        Text("LEVEL").font(.ui(13, .heavy)).tracking(2).foregroundStyle(Theme.ink.opacity(0.75))
                        Text("\(level)").font(.num(62, .heavy)).foregroundStyle(Theme.ink)
                    }
                    SparkBurst(trigger: pop, color: Theme.champagne, radius: 120, count: 14)
                }
                .scaleEffect(badgeIn ? 1 : 0.2).rotationEffect(.degrees(badgeIn ? 0 : -40)).opacity(badgeIn ? 1 : 0)
                .padding(.top, 70)

                Text("LEVEL UP!").font(.story(38, .bold)).tracking(1.5).foregroundStyle(Theme.champagne)
                    .padding(.top, 22)
                    .scaleEffect(titleIn ? 1 : 1.6).opacity(titleIn ? 1 : 0)

                // The Flame's bar, now into the new level.
                ZStack {
                    XPBar(fill: barFill, height: 20, colors: [Theme.champagne, Theme.gold], flash: pop)
                    Text("\(l.into) / \(l.span) XP").font(.num(12, .bold)).foregroundStyle(Theme.cream)
                        .shadow(color: .black.opacity(0.6), radius: 1, y: 1)
                }
                .overlay(alignment: .leading) {
                    Text("XP").font(.ui(10, .heavy)).foregroundStyle(Theme.ink)
                        .frame(width: 30, height: 30).background(Circle().fill(Theme.champagne))
                        .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1)).offset(x: -10)
                }
                .padding(.horizontal, 40).padding(.top, 20)
                .opacity(titleIn ? 1 : 0)

                Rectangle().fill(Theme.cream.opacity(0.14)).frame(height: 0.5).padding(.horizontal, 32).padding(.vertical, 22)

                // What you earned (all real: the Embers are granted on Collect).
                VStack(alignment: .leading, spacing: 18) {
                    reward(0, icon: AnyView(EmberCoin(size: 34)), title: "+\(bonus) EMBERS", line: "For reaching level \(level).")
                    reward(1, icon: AnyView(Image(uiImage: UIImage(named: "pillar-\(outcome.pillar.rawValue.lowercased()).png") ?? UIImage()).resizable().scaledToFit().frame(width: 36, height: 36)),
                           title: skillAfter > skillBefore ? "\(outcome.pillar.attribute.uppercased()) LEVEL \(skillAfter)" : "\(outcome.pillar.attribute.uppercased()) +\(outcome.xp)",
                           line: skillAfter > skillBefore ? "Your \(outcome.pillar.attribute.lowercased()) reached a new level too." : "Level \(skillAfter), a little closer to the next.")
                    reward(2, icon: AnyView(Image(uiImage: UIImage(named: PixelMode.world ? "px-icon-flame.png" : "icon-flame-v2.png") ?? UIImage()).resizable().interpolation(.none).scaledToFit().frame(width: 34, height: 34)),
                           title: nextFormTitle, line: nextFormLine)
                }
                .padding(.horizontal, 34)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
                Button {
                    guard !collected else { return }
                    collected = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    collect(CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.height - 90))
                } label: {
                    Text("Collect").font(.story(22, .semibold)).foregroundStyle(Color(red: 0.27, green: 0.15, blue: 0.06))
                        .frame(maxWidth: .infinity).frame(height: 60)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LinearGradient(colors: [Color(red: 1, green: 0.93, blue: 0.75), Theme.champagne], startPoint: .top, endPoint: .bottom)))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.champagneDeep, lineWidth: 1))
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.warmShadow.opacity(0.5)).offset(y: 5))
                }
                .buttonStyle(PressableStyle())
                .padding(.horizontal, 22).padding(.bottom, 24)
                .opacity(rowsIn >= 3 ? 1 : 0).offset(y: rowsIn >= 3 ? 0 : 20)
            }
        }
        .onAppear(perform: run)
    }

    private var nextFormTitle: String {
        guard let n = journey.reachedForm.next else { return "EVERY FORM IS YOURS" }
        return "NEXT FORM: \(n.name.uppercased())"
    }
    private var nextFormLine: String {
        guard let n = journey.reachedForm.next else { return "Your Flame has reached its last form." }
        let left = max(1, n.days - journey.streak().best)
        return "\(left) more day\(left == 1 ? "" : "s") in a row and your Flame grows."
    }

    private func reward(_ i: Int, icon: AnyView, title: String, line: String) -> some View {
        HStack(spacing: 16) {
            icon.frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.ui(16, .heavy)).tracking(0.6).foregroundStyle(Theme.cream)
                Text(line).font(.ui(13)).foregroundStyle(Theme.cream.opacity(0.6))
            }
        }
        .opacity(rowsIn > i ? 1 : 0).offset(x: rowsIn > i ? 0 : -24)
    }

    private func run() {
        let l = Progression.level(xp: outcome.totalXPAfter)
        XPHaptics.levelUp()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) { badgeIn = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            pop += 1
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { titleIn = true }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { twinkle = true }
            try? await Task.sleep(for: .milliseconds(300))
            XPHaptics.fill(ticks: 5, over: 0.7)
            withAnimation(.easeOut(duration: 0.7)) { barFill = CGFloat(l.into) / CGFloat(max(1, l.span)) }
            try? await Task.sleep(for: .milliseconds(450))
            for i in 1...3 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { rowsIn = i }
                try? await Task.sleep(for: .milliseconds(220))
            }
        }
    }
}
