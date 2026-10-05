// Friends (decision 137): your friends' Flames, their streaks, how they're doing, the challenges they completed.
// Only what is verifiably done and that the friend chose to share is shown; no rankings that shame. Until P5 (the
// Apple program, CloudKit sharing) these are sample friends, so the screens can be lived with and tuned now.
import SwiftUI

struct Friend: Identifiable {
    struct Done: Identifiable { let id = UUID(); let title: String; let realm: RealmID; let daysAgo: Int; let streak: Int }
    let id: String
    let name: String
    let ember: String
    let stage: String
    let level: Int
    let streak: Int
    let best: Int
    let week: [Bool]                 // Monday → Sunday: days lived
    let worlds: Int                  // worlds opened
    let strongest: Pillar6
    let done: [Done]                 // only verified quests they chose to share

    var line: String {
        let lived = week.filter { $0 }.count
        switch lived {
        case 5...: return "Burning bright this week"
        case 3...4: return "A steady glow"
        case 1...2: return "Finding their rhythm"
        default: return "Resting lately"
        }
    }

    /// Sample friends (P5 brings real ones through iCloud sharing).
    static let samples: [Friend] = [
        Friend(id: "lea", name: "Léa", ember: "heart", stage: "Flame", level: 6, streak: 23, best: 23,
               week: [true, true, true, true, true, false, false], worlds: 4, strongest: .heart,
               done: [Done(title: "A lantern for someone", realm: .wilds, daysAgo: 0, streak: 12),
                      Done(title: "Three slow breaths", realm: .stillwater, daysAgo: 0, streak: 23),
                      Done(title: "Ten pages", realm: .library, daysAgo: 1, streak: 5)]),
        Friend(id: "sam", name: "Sam", ember: "body", stage: "Spark", level: 3, streak: 6, best: 14,
               week: [true, false, true, true, true, false, false], worlds: 2, strongest: .body,
               done: [Done(title: "A moment outside", realm: .highlands, daysAgo: 0, streak: 6),
                      Done(title: "Twenty squats", realm: .highlands, daysAgo: 2, streak: 3)]),
        Friend(id: "noor", name: "Noor", ember: "mind", stage: "Flame", level: 9, streak: 41, best: 41,
               week: [true, true, true, true, true, false, false], worlds: 6, strongest: .mind,
               done: [Done(title: "One focused block", realm: .forge, daysAgo: 0, streak: 41),
                      Done(title: "Ten pages", realm: .library, daysAgo: 0, streak: 30),
                      Done(title: "Notice something alive", realm: .wilds, daysAgo: 1, streak: 8)]),
        Friend(id: "tom", name: "Tom", ember: "spirit", stage: "Spark", level: 2, streak: 0, best: 9,
               week: [false, true, false, false, false, false, false], worlds: 1, strongest: .spirit,
               done: [Done(title: "Three slow breaths", realm: .stillwater, daysAgo: 4, streak: 1)]),
    ]
}

/// The row of friends in Your Flame: their Sparks and streaks; tap one to open their profile.
struct FriendsStrip: View {
    let friends: [Friend]
    let open: (Friend) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Friends").font(.ui(15, .bold)).foregroundStyle(Theme.ink)
                Spacer()
                Text("sample friends until sharing arrives").font(.ui(10)).foregroundStyle(Theme.ink.opacity(0.45))
            }
            HStack(spacing: 0) {
                ForEach(friends) { f in
                    Button { open(f) } label: {
                        VStack(spacing: 3) {
                            Image(uiImage: SparkTint.image("spark-keyed.png", ember: f.ember) ?? UIImage()).resizable().scaledToFit()
                                .frame(height: 44).opacity(f.streak > 0 ? 1 : 0.55)
                            Text(f.name).font(.ui(12, .bold)).foregroundStyle(Theme.ink)
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill").font(.system(size: 9))
                                Text("\(f.streak)").font(.num(11, .bold))
                            }
                            .foregroundStyle(f.streak > 0 ? Theme.accent : Theme.ink.opacity(0.35))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }
}

/// A friend's profile: their Flame, streak, level, their week, the worlds they've opened, and the challenges they
/// completed (verified, shared by them). A cheer is the only thing you can send: warm, never a nudge or a ranking.
struct FriendProfile: View {
    let friend: Friend
    let close: () -> Void
    @State private var cheered = false
    private let ink = Theme.ink

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35).ignoresSafeArea().onTapGesture(perform: close)
            VStack(spacing: 14) {
                Capsule().fill(ink.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 10)
                ZStack {
                    Circle().fill(RadialGradient(colors: [Color.orange.opacity(0.4), .clear], center: .center, startRadius: 4, endRadius: 64)).frame(width: 130, height: 130)
                    Image(uiImage: SparkTint.image("spark-keyed.png", ember: friend.ember) ?? UIImage()).resizable().scaledToFit().frame(height: 92)
                }
                .frame(height: 104)
                VStack(spacing: 2) {
                    Text("\(friend.name)'s \(friend.stage)").font(.story(24)).foregroundStyle(ink)
                    Text(friend.line).font(.ui(13, .semibold)).foregroundStyle(Theme.accent)
                }
                HStack(spacing: 10) {
                    stat("\(friend.streak)", "days in a row", icon: "flame.fill")
                    stat("\(friend.level)", "level", icon: "star.fill")
                    stat("\(friend.worlds)", friend.worlds == 1 ? "world" : "worlds", icon: "map.fill")
                }
                week.padding(12).paperCard(14)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completed lately").font(.ui(14, .bold)).foregroundStyle(ink)
                    ForEach(friend.done) { d in
                        HStack(spacing: 10) {
                            Image(systemName: d.realm.symbol).font(.system(size: 14, weight: .semibold)).foregroundStyle(d.realm.color)
                                .frame(width: 30, height: 30).background(Circle().fill(Theme.night.opacity(0.85)))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(d.title).font(.ui(14, .semibold)).foregroundStyle(ink)
                                Text("\(d.daysAgo == 0 ? "today" : d.daysAgo == 1 ? "yesterday" : "\(d.daysAgo) days ago") · \(d.streak)-day streak")
                                    .font(.ui(11)).foregroundStyle(ink.opacity(0.55))
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(Color(red: 0.3, green: 0.6, blue: 0.35))   // verified
                        }
                    }
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading).paperCard(14)
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { cheered = true }
                } label: {
                    Label(cheered ? "Cheer sent" : "Send a cheer", systemImage: cheered ? "heart.fill" : "hands.clap.fill").font(.ui(16, .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Capsule().fill(LinearGradient(colors: [Theme.gold, Color(red: 0.95, green: 0.55, blue: 0.25)], startPoint: .top, endPoint: .bottom)))
                        .foregroundStyle(Color(red: 0.25, green: 0.12, blue: 0.05))
                }
                .disabled(cheered)
                .buttonStyle(PressableStyle())
            }
            .padding(.horizontal, 18).padding(.bottom, 18)
            .background(SheetPaper())
            .padding(.horizontal, 10).padding(.bottom, 8)
        }
    }

    private func stat(_ big: String, _ label: String, icon: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 12)).foregroundStyle(Theme.accent)
                Text(big).font(.num(22, .heavy)).foregroundStyle(ink)
            }
            Text(label).font(.ui(11)).foregroundStyle(ink.opacity(0.6))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10).paperCard(14)
    }

    private var week: some View {
        HStack {
            ForEach(Array(zip(["M", "T", "W", "T", "F", "S", "S"], friend.week).enumerated()), id: \.offset) { _, d in
                VStack(spacing: 3) {
                    Image(systemName: "flame.fill").font(.system(size: 17))
                        .foregroundStyle(d.1 ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 0.85, blue: 0.4), .orange], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(ink.opacity(0.15)))
                    Text(d.0).font(.ui(10)).foregroundStyle(ink.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
