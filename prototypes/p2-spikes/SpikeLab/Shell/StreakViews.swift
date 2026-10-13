// The streak at the core, on screen (decision 134): the flame counter and the day of the arc at the top of home in
// every world, the line that tells you where your streak stands today, and the reward moment when a quest is done
// (+XP, the attribute counting up, a level-up, a streak milestone celebrated in the world).
import SwiftUI

private let gold = Color(red: 1, green: 0.78, blue: 0.42)
private let ember = Color(red: 1, green: 0.55, blue: 0.22)

/// 🔥 14 · 🛡 1 · Day 4 / 7 (the day of your round)
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
            Text("Day \(journey.roundDay) / \(journey.roundLength)")
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

/// Your Flame's message of the day (Mathis, 2026-10-13, task 4): the same from morning to night, a new one each
/// morning, and always about *why* the small daily quests matter, not only inspiration. (The streak's ups and downs are
/// told at the moment they happen: the reward, the round card.)
func flameLine(_ j: Journey) -> String { DailyWhy.today() }

enum DailyWhy {
    static let messages = [
        "1% better each day is 37 times better in a year. That's why we never skip.",
        "One push-up won't change you. One every day for a year will.",
        "Every quest is a vote for who you're becoming.",
        "Big changes are just small days, stacked.",
        "Motivation fades. Habits stay. That's why today counts.",
        "The days you don't feel like it are the ones that build you.",
        "After about two months, the things you do daily start doing themselves.",
        "Small enough to do every day is strong enough to change a life.",
        "Your brain rewires around what you repeat. Let's repeat the good.",
        "A missed day is a bump. Two in a row is a new habit. Let's never miss twice.",
        "I grow from the days you keep, not the hours you spend.",
        "Ten pages a day is a dozen books a year. Small adds up.",
        "Strength isn't built in one workout. It's built in the next one, and the next.",
        "Today's small quest is tomorrow's normal.",
        "Every day you show up, the next one gets easier.",
        "Not a perfect day: an unbroken chain of good-enough ones.",
        "Habits compound like money: slowly, then all at once.",
        "Calm, strength, focus: none of them arrive. They're practised.",
        "We don't need a big leap. We need a small step we never stop taking.",
        "Who you are in a year is decided on ordinary days like this one.",
        "Consistency beats intensity. Every single time.",
        "Each quest you finish tells your brain: this is who we are now.",
        "A little every day is how mountains are climbed.",
        "Don't break the chain. That's the whole secret.",
        "Hard days count double. Showing up on them is how you get strong.",
        "It's not about today's quest. It's about the person who does it every day.",
        "Small and daily beats big and someday.",
        "Your future self is built from today's tiny choices.",
        "The quest is small on purpose: so nothing can stop us doing it today.",
        "Every day you keep, I burn a little steadier. So do you.",
    ]
    /// One per calendar day (stable all day, a new one each morning).
    static func today(_ date: Date = Date()) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return messages[day % messages.count]
    }
}

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

/// A round is over (decision 159): celebrate it, say honestly how many of its days you came back, and choose the next
/// round. Never a judgement: every day you lived counts, and the next round starts today.
struct RoundComplete: View {
    let length: Int, lived: Int, round: Int
    let choose: (Int) -> Void
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame.fill").font(.system(size: 40))
                .foregroundStyle(LinearGradient(colors: [Color(red: 1, green: 0.88, blue: 0.55), Color(red: 1, green: 0.55, blue: 0.25)], startPoint: .top, endPoint: .bottom))
                .shadow(color: Theme.gold.opacity(0.6), radius: 14)
            Text(round == 1 ? "Your first round is done" : "Round \(round) is done").font(.story(22)).foregroundStyle(Theme.ink)
            Text(lived >= length ? "\(length) days, and you came back every single one. That's the whole secret."
                 : "\(length) days. You came back on \(lived) of them, and your Flame remembers every one.")
                .font(.ui(13)).foregroundStyle(Theme.ink.opacity(0.7)).multilineTextAlignment(.center)
            Text("How long for the next round?").font(.story(16, .medium)).foregroundStyle(Theme.ink).padding(.top, 4)
            ForEach(Journey.roundChoices, id: \.self) { n in
                Button { UIImpactFeedbackGenerator(style: .medium).impactOccurred(); choose(n) } label: {
                    ParchmentChoice(text: n == length ? "\(n) days · again" : "\(n) days", selected: n == Self.suggested(after: length))
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(22)
        .background(SheetPaper(corner: 24))
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.35).ignoresSafeArea())
    }
    /// A gentle step up: after 7, suggest 14; after 14, 30; after 30, 30 again.
    static func suggested(after n: Int) -> Int { Journey.roundChoices.first { $0 > n } ?? n }
}
