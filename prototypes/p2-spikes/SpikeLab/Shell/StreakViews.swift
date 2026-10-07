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
                VStack(spacing: 10) {
                    Text("+\(outcome.xp) XP").font(.num(34, .heavy)).foregroundStyle(gold)
                        .shadow(color: ember.opacity(0.8), radius: 12)
                        .offset(y: shown ? -30 : 20).opacity(shown ? 1 : 0)
                    HStack(spacing: 8) {
                        Image(systemName: outcome.pillar.realm.symbol).foregroundStyle(outcome.pillar.realm.color)
                        Text(outcome.pillar.attribute).font(.ui(15, .bold))
                        Text("\(counted)").font(.num(22, .bold)).monospacedDigit()
                            .contentTransition(.numericText(value: Double(counted)))
                        Image(systemName: "arrowtriangle.up.fill").font(.system(size: 10)).foregroundStyle(Color(red: 0.5, green: 0.9, blue: 0.5))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(Capsule().fill(.black.opacity(0.6))).overlay(Capsule().stroke(outcome.pillar.realm.color.opacity(0.6), lineWidth: 1))
                    .opacity(shown ? 1 : 0).scaleEffect(shown ? 1 : 0.8)
                    if outcome.streakAfter > outcome.streakBefore {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill").foregroundStyle(ember)
                            Text(outcome.streakAfter == 1 ? "Your flame is lit" : "\(outcome.streakAfter) days in a row").font(.ui(14, .bold))
                        }
                        .foregroundStyle(.white).padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Capsule().fill(.black.opacity(0.55)))
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
        let title: String = outcome.milestone.map { "\($0) days in a row" } ?? "Level \(outcome.levelAfter)"
        let line: String = outcome.milestone.map { m in m >= 66 ? "Sixty-six days. This is who you are now." : "Your flame burns steadier every day." } ?? "Every quest makes you a little more you."
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea().onTapGesture { finish() }
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(RadialGradient(colors: [ember.opacity(0.7), .clear], center: .center, startRadius: 4, endRadius: 90)).frame(width: 180, height: 180)
                    Image(systemName: outcome.milestone != nil ? "flame.fill" : "star.fill").font(.system(size: 64))
                        .foregroundStyle(LinearGradient(colors: [Color(red: 1, green: 0.92, blue: 0.55), ember], startPoint: .top, endPoint: .bottom))
                }
                Text(title).font(.story(32)).foregroundStyle(.white)
                Text(line).font(.ui(16)).foregroundStyle(.white.opacity(0.85))
                if outcome.shieldEarned {
                    Label("You earned a shield: one missed day won't break your flame", systemImage: "shield.fill")
                        .font(.ui(13)).foregroundStyle(Color(red: 0.75, green: 0.88, blue: 1))
                        .multilineTextAlignment(.center).padding(.horizontal, 30)
                }
                Button { finish() } label: {
                    GoldButtonLabel(text: "Keep going")
                }
                .padding(.top, 6)
            }
        }
    }

    private func run() {
        counted = outcome.attributeBefore
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { shown = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.easeOut(duration: 0.8)) { counted = outcome.attributeAfter }       // the number climbs
            try? await Task.sleep(for: .milliseconds(1400))
            if outcome.milestone != nil || outcome.levelAfter > outcome.levelBefore {
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
