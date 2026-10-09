// The streak at the core, on screen (decision 134): the flame counter and the day of the arc at the top of home in
// every world, the line that tells you where your streak stands today, and the reward moment when a quest is done
// (+XP, the attribute counting up, a level-up, a streak milestone celebrated in the world).
import SwiftUI

private let gold = Color(red: 1, green: 0.78, blue: 0.42)
private let ember = Color(red: 1, green: 0.55, blue: 0.22)

/// 🔥 14 · 🛡 1 · Day 14 / 66
struct StreakBar: View {
    let journey: Journey
    var body: some View {
        let _ = PerfProbe.body("StreakBar")
        let s = journey.streak()
        let lit = s.state == .livedToday
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(lit ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 0.9, blue: 0.5), ember], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Color.white.opacity(0.55)))
                Text("\(s.current)").font(.num(15, .bold)).monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(lit ? ember.opacity(0.32) : .black.opacity(0.45)))
            .overlay(Capsule().stroke(lit ? ember.opacity(0.9) : .white.opacity(0.2), lineWidth: 1))
            if s.shields > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<s.shields, id: \.self) { _ in Image(systemName: "shield.fill").font(.system(size: 11)) }
                }
                .foregroundStyle(Color(red: 0.7, green: 0.85, blue: 1))
                .padding(.horizontal, 8).padding(.vertical, 5).background(Capsule().fill(.black.opacity(0.45)))
            }
            Text("Day \(min(journey.dayNumber(), Progression.arcLength)) / \(Progression.arcLength)")
                .font(.ui(13, .bold)).foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 10).padding(.vertical, 5).background(Capsule().fill(.black.opacity(0.45)))
        }
        .foregroundStyle(.white)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: s.current)
    }
}

/// One warm line about today and your streak.
func streakLine(_ j: Journey, light: Int) -> String {
    let s = j.streak()
    switch s.state {
    case .livedToday:
        let days = s.current == 1 ? "1 day" : "\(s.current) days"
        return light <= 1 ? (s.current == 1 ? "Day kept · your flame is lit" : "Day kept · your flame burns \(days) strong") : "\(light) lights sent today · \(days) strong"
    case .waiting: return s.current > 0 ? "One quest today keeps your \(s.current)-day flame alive" : "Your day is ready"
    case .shieldedYesterday: return "A shield caught yesterday · your \(s.current)-day flame lives on"
    case .repairable(let need): return need >= 2 ? "Live 2 quests today to save your \(s.current)-day flame" : "One more quest today saves your \(s.current)-day flame"
    case .broken: return s.best > 0 ? "A new flame starts with one quest (your best: \(s.best) days)" : "Your day is ready"
    }
}

/// The moment a quest is done: +XP flies up, the pillar's number counts up, and a level-up or a streak milestone
/// gets its own celebration.
struct RewardBurst: View {
    let outcome: DeedOutcome
    let done: () -> Void
    @State private var shown = false
    @State private var counted: Int = 0
    @State private var stage = 0          // 0 = XP and attribute, 1 = milestone / level (if any)
    var body: some View {
        ZStack {
            if stage == 0 {
                // Quiet (decision 146): a few words of light, no boxes; the number climbs, then it all fades.
                VStack(spacing: 8) {
                    Text("+\(outcome.xp) XP").font(.story(30, .medium)).foregroundStyle(Theme.champagne)
                        .shadow(color: Color(red: 1, green: 0.6, blue: 0.25).opacity(0.6), radius: 10).shadow(color: .black.opacity(0.6), radius: 6)
                        .offset(y: shown ? -20 : 10).opacity(shown ? 1 : 0)
                    HStack(spacing: 8) {
                        Image(uiImage: UIImage(named: "pillar-\(outcome.pillar.rawValue.lowercased()).png") ?? UIImage()).resizable().scaledToFit().frame(width: 26, height: 26)
                        Text(outcome.pillar.attribute).font(.story(16).italic())
                        Text("\(counted)").font(.num(19, .bold)).monospacedDigit()
                            .contentTransition(.numericText(value: Double(counted)))
                    }
                    .foregroundStyle(Theme.cream)
                    .shadow(color: .black.opacity(0.85), radius: 5)
                    .opacity(shown ? 1 : 0).offset(y: shown ? 0 : 6)
                    if outcome.streakAfter > outcome.streakBefore {
                        Text(outcome.streakAfter == 1 ? "Your flame is lit" : "\(outcome.streakAfter) days in a row · this day counts as much as any").font(.story(15).italic())
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.cream.opacity(0.85)).shadow(color: .black.opacity(0.85), radius: 5)
                            .opacity(shown ? 1 : 0)
                    }
                }
                .offset(y: -190)                    // in the sky above your Spark, never over it
                .transition(.opacity)
            } else {
                celebration.transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .allowsHitTesting(stage == 1)
        .onAppear(perform: run)
    }

    @ViewBuilder private var celebration: some View {
        let title: String = outcome.evolvedTo.map { "Your Flame became a \($0.name)" } ?? outcome.milestone.map { "\($0) days in a row" } ?? "Level \(outcome.levelAfter)"
        let line: String = outcome.evolvedTo.map { "\($0.days) days in a row. This form is yours for good." } ?? outcome.milestone.map { m in m >= 66 ? "Sixty-six days. This is who you are now." : "Your flame burns steadier every day." } ?? "Every quest makes you a little more you."
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { finish() }
            VStack(spacing: 12) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [Theme.champagne.opacity(0.55), .clear], center: .center, startRadius: 4, endRadius: 70)).frame(width: 140, height: 140)
                    if let f = outcome.evolvedTo, let img = UIImage(named: f.base + "-keyed.png") {
                        Image(uiImage: img).resizable().interpolation(.none).scaledToFit().frame(height: 104)     // the new form
                    } else {
                        Image(uiImage: UIImage(named: "wax-seal.png") ?? UIImage()).resizable().scaledToFit().frame(width: 74, height: 74)
                    }
                    if outcome.milestone == nil && outcome.evolvedTo == nil {
                        Text("\(outcome.levelAfter)").font(.num(26, .heavy)).foregroundStyle(Theme.cream).shadow(color: .black.opacity(0.4), radius: 2)
                    }
                }
                .frame(height: 110)
                Text(title).font(.story(28, .medium)).foregroundStyle(Theme.ink)
                Text(line).font(.story(16).italic()).foregroundStyle(Theme.ink.opacity(0.7)).multilineTextAlignment(.center)
                if outcome.shieldEarned {
                    Text("You earned a shield: one missed day won't put your flame out.")
                        .font(.ui(13)).foregroundStyle(Theme.ink.opacity(0.6)).multilineTextAlignment(.center)
                }
                Button { finish() } label: { GoldButtonLabel(text: "Keep going") }
                    .buttonStyle(PressableStyle()).padding(.top, 8)
            }
            .padding(.horizontal, 26).padding(.vertical, 24)
            .background(SheetPaper(corner: 26))
            .padding(.horizontal, 34)
        }
    }

    private func run() {
        counted = outcome.attributeBefore
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { shown = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.easeOut(duration: 0.8)) { counted = outcome.attributeAfter }       // the number climbs
            try? await Task.sleep(for: .milliseconds(1400))
            if outcome.evolvedTo != nil || outcome.milestone != nil || outcome.levelAfter > outcome.levelBefore {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { stage = 1 }
            } else {
                withAnimation(.easeIn(duration: 0.3)) { shown = false }
                try? await Task.sleep(for: .milliseconds(300))
                done()
            }
        }
    }
    private func finish() { withAnimation(.easeOut(duration: 0.25)) { done() } }
}

/// Your Flame's line of the day (Mathis's notes: "daily quote based on the last days' completions"): written from
/// your real record, warm, never guilt. The same line all day; a new one tomorrow.
func flameLine(_ j: Journey) -> String {
    let cal = Calendar.current
    let s = j.streak()
    func count(daysAgo d: Int) -> Int {
        guard let day = cal.date(byAdding: .day, value: -d, to: Date()) else { return 0 }
        return j.deeds.filter { cal.isDate($0.date, inSameDayAs: day) }.count
    }
    let today = count(daysAgo: 0), yesterday = count(daysAgo: 1)
    let week = (0..<7).filter { count(daysAgo: $0) > 0 }.count
    let next = j.reachedForm.next
    var options: [String]
    switch s.state {
    case .livedToday:
        options = today >= 3 ? ["Three today! I can feel myself growing.", "What a day. I'm burning bright."]
                             : ["Thank you. I feel warm.", "That's the light I needed today."]
    case .waiting where s.current >= 3:
        options = ["\(s.current) days in a row. One small thing keeps us going.", "We're on a streak. I'm ready when you are."]
    case .shieldedYesterday:
        options = ["A shield caught yesterday. Today, let's light us up again."]
    case .repairable:
        options = ["We missed a day. Two small things today and our streak lives on."]
    case .broken where s.best > 0:
        options = ["Every flame flickers. One small thing and I'm warm again.", "New day, new light. I'm still here."]
    default:
        options = yesterday > 0 ? ["Yesterday was good. Shall we do it again?"] : ["Good to see you. Let's start small."]
    }
    if let n = next, s.state != .broken, n.days - s.best <= 2, n.days > s.best {
        options = ["\(n.days - s.best) more day\(n.days - s.best == 1 ? "" : "s") and I become a \(n.name)!"]
    } else if week >= 6 { options.append("Six of the last seven days. You're becoming someone new.") }
    if j.dayNumber() % 3 == 0 && s.state != .repairable(need: 2) && s.state != .repairable(need: 1) {
        options = ["Small or big, it doesn't matter. Every day does.", "I don't need big. I need every day.", "It's not how much. It's never stopping."]
    }
    return options[j.dayNumber() % options.count]
}

/// The heart of Hush (Mathis, 2026-10-09): it's not how hard a quest is, it's doing it every day without a break.
/// Said often, in a few different words, so it never sounds like a slogan.
enum Consistency {
    static let lines = [
        "Small is fine. What counts is doing it every day.",
        "It's not about how hard it is. It's about not missing a day.",
        "A tiny quest kept every day beats a big one done once.",
        "Easy or hard, every day you keep is what changes you.",
        "Showing up today matters more than how much you do.",
    ]
    static func line(_ salt: Int = 0) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return lines[abs(day + salt) % lines.count]
    }
}
