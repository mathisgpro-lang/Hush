// Your Flame (decision 128): where you are in your journey. Your Spark, large and alive in your ember's color; its
// stage and the ones to come; this week's seven little flames (missed days are simply unlit, a fresh week every
// Monday); the days you've lived (it only grows); your six lights; how bright you've been lately; what's next.
// No streak, nothing that can break.
import SwiftUI

struct FlameSheet: View {
    let model: ShellModel
    @Binding var isOpen: Bool
    @State private var bob = false
    private let cream = Color(red: 1, green: 0.95, blue: 0.86)
    private let gold = Color(red: 1, green: 0.78, blue: 0.42)
    private static let stages = ["stage-spark", "stage-flame", "stage-blaze", "stage-kindled", "stage-beyond"]
    private static let stageNames = ["Spark", "Flame", "Blaze", "Kindled", "Beyond"]
    private static let lights: [(RealmID, String)] = [(.grove, "Heart"), (.library, "Mind"), (.highlands, "Body"),
                                                       (.stillwater, "Spirit"), (.forge, "Craft"), (.wilds, "World")]
    private var j: Journey { model.journey }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { close() }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Capsule().fill(cream.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 10)
                    // Your Spark, alive.
                    Image(uiImage: SparkTint.image("spark-keyed.png", ember: model.emberID) ?? UIImage()).resizable().scaledToFit()
                        .frame(height: 120).offset(y: bob ? -5 : 3)
                        .shadow(color: .orange.opacity(0.6), radius: bob ? 22 : 14)
                        .animation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true), value: bob)
                    VStack(spacing: 2) {
                        Text(j.name.isEmpty ? "Your Spark" : "\(j.name)'s Spark").font(.system(size: 26, design: .serif)).foregroundStyle(cream)
                        Text("Spark · day \(j.dayNumber())").font(.system(size: 14, design: .serif)).foregroundStyle(gold)
                    }
                    stageStrip
                    card { week }
                    HStack(spacing: 12) {
                        card { stat("\(j.daysLived)", "days lived", "Every day you live counts, forever.") }
                        card { stat("\(j.lastSeven)/7", "lately", vitalityLine) }
                    }
                    card { sixLights }
                    card {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles").foregroundStyle(gold)
                            Text(nextLine).font(.system(size: 15, design: .serif)).foregroundStyle(cream)
                            Spacer()
                        }
                    }
                    Spacer().frame(height: 10)
                }
                .padding(.horizontal, 18)
            }
            .frame(maxHeight: 680)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color(red: 0.1, green: 0.07, blue: 0.09).opacity(0.97))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(gold.opacity(0.4), lineWidth: 1)))
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
                        .shadow(color: i == 0 ? .orange : .clear, radius: 8)
                    Text(i == 4 ? "?" : Self.stageNames[i]).font(.system(size: 10, design: .serif)).foregroundStyle(cream.opacity(i == 0 ? 1 : 0.45))
                }
            }
        }
    }

    private var week: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This week").font(.system(size: 15, weight: .semibold, design: .serif)).foregroundStyle(cream)
            HStack {
                ForEach(Array(zip(["M", "T", "W", "T", "F", "S", "S"], j.thisWeek).enumerated()), id: \.offset) { _, d in
                    VStack(spacing: 4) {
                        Image(systemName: "flame.fill").font(.system(size: 20))
                            .foregroundStyle(d.1 ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 0.9, blue: 0.5), .orange], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(cream.opacity(0.15)))
                            .shadow(color: d.1 ? .orange.opacity(0.8) : .clear, radius: 6)
                        Text(d.0).font(.system(size: 11, design: .serif)).foregroundStyle(cream.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            Text("A fresh week begins every Monday.").font(.system(size: 12, design: .serif)).foregroundStyle(cream.opacity(0.5))
        }
    }

    private var sixLights: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your six lights").font(.system(size: 15, weight: .semibold, design: .serif)).foregroundStyle(cream)
            ForEach(Self.lights, id: \.1) { realm, pillar in
                let n = j.light(for: realm), level = n / 3 + 1, part = CGFloat(n % 3) / 3
                HStack(spacing: 10) {
                    Image(systemName: realm.symbol).foregroundStyle(realm.color).frame(width: 22)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(pillar).font(.system(size: 14, design: .serif)).foregroundStyle(cream)
                            Text("· \(realm.name)").font(.system(size: 11, design: .serif)).foregroundStyle(cream.opacity(0.45))
                            Spacer()
                            Text(n == 0 ? "not lit yet" : "level \(level)").font(.system(size: 11, design: .serif)).foregroundStyle(n == 0 ? cream.opacity(0.4) : realm.color)
                        }
                        Capsule().fill(cream.opacity(0.1)).frame(height: 5)
                            .overlay(alignment: .leading) { GeometryReader { g in
                                Capsule().fill(realm.color).frame(width: g.size.width * max(n == 0 ? 0 : 0.08, part)).shadow(color: realm.color, radius: 4)
                            } }
                    }
                }
            }
        }
    }

    private func card<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        c().padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08), lineWidth: 1))
    }

    private func stat(_ big: String, _ label: String, _ line: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(big).font(.system(size: 30, design: .serif)).foregroundStyle(gold)
            Text(label).font(.system(size: 13, weight: .semibold, design: .serif)).foregroundStyle(cream)
            Text(line).font(.system(size: 11, design: .serif)).foregroundStyle(cream.opacity(0.55)).fixedSize(horizontal: false, vertical: true)
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
