// Your day, on home (Mathis, 2026-10-07, after Finch: "the missions should be part of the home screen, the main thing
// people see, always here, with a tick system"). Today's quests in a list under the world, one tap on the tick to do
// one: the check fills, the Embers fly to your counter, the light flies to your Spark. Tap a quest itself for its
// details (progress, skip). "+" opens the satchel to add or swap.
import SwiftUI

struct QuestBoard: View {
    let calls: [Call]                     // today's quests (taken), not done first
    let streakLine: String
    let add: () -> Void
    let open: (Call) -> Void
    let tick: (Call, CGPoint) -> Void

    private var left: Int { calls.filter { !$0.done }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(left == 0 ? (calls.isEmpty ? "Your day is ready" : "All done today") : left == 1 ? "1 quest left today" : "\(left) quests left today")
                    .font(.story(17, .medium)).foregroundStyle(Theme.cream)
                Spacer()
                Button(action: add) {
                    Image(systemName: "plus").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.cream)
                        .frame(width: 32, height: 32).background(Circle().fill(.white.opacity(0.1)))
                        .overlay(Circle().stroke(Theme.champagne.opacity(0.3), lineWidth: 0.5))
                        .contentShape(Circle())
                }
                .buttonStyle(PressableStyle())
            }
            .padding(.horizontal, 4)
            Text(streakLine).font(.story(13).italic()).foregroundStyle(Theme.cream.opacity(0.6)).padding(.horizontal, 4).padding(.top, -6)
            if calls.isEmpty {
                Button(action: add) {
                    Text("Choose today's quests").font(.story(16)).foregroundStyle(Theme.cream.opacity(0.85))
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.champagne.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                }
            }
            ForEach(calls) { c in QuestRow(call: c, open: { open(c) }, tick: { p in tick(c, p) }) }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.black.opacity(0.58)))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.champagne.opacity(0.2), lineWidth: 0.5))
        .animation(Motion.soft, value: calls.map(\.done))
    }
}

struct QuestRow: View {
    let call: Call
    let open: () -> Void
    let tick: (CGPoint) -> Void
    @State private var tickCenter: CGPoint = .zero
    @State private var pressed = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: open) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(call.realm.color.opacity(0.18)).frame(width: 40, height: 40)
                        Image(uiImage: UIImage(named: "\(call.prop).png") ?? UIImage()).resizable().scaledToFit().frame(width: 28, height: 28)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(call.title).font(.story(16, .medium)).foregroundStyle(Theme.cream.opacity(call.done ? 0.45 : 1))
                            .strikethrough(call.done, color: Theme.cream.opacity(0.4)).lineLimit(1)
                        HStack(spacing: 6) {
                            Text(call.counted && !call.done ? "\(call.progress)/\(call.target) \(call.unit)" : "\(call.minutes) min")
                            Text("·")
                            HStack(spacing: 3) { EmberCoin(size: 11); Text("+10") }
                        }
                        .font(.ui(12, .semibold)).foregroundStyle(Theme.cream.opacity(call.done ? 0.35 : 0.6))
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // The tick: one tap and it's done.
            Button {
                guard !call.done else { return }
                tick(tickCenter)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(call.done ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 0.92, blue: 0.72), Theme.champagne], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Color.white.opacity(0.08)))
                    RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.champagne.opacity(call.done ? 0 : 0.45), lineWidth: 1)
                    Image(systemName: "checkmark").font(.system(size: 18, weight: .bold))
                        .foregroundStyle(call.done ? Color(red: 0.35, green: 0.2, blue: 0.06) : Theme.champagne.opacity(0.7))
                        .scaleEffect(call.done ? 1.1 : 1)
                }
                .frame(width: 50, height: 46)
                .background(GeometryReader { g in Color.clear.onAppear { tickCenter = CGPoint(x: g.frame(in: .global).midX, y: g.frame(in: .global).midY) }
                    .onChange(of: g.frame(in: .global)) { _, f in tickCenter = CGPoint(x: f.midX, y: f.midY) } })
            }
            .buttonStyle(PressableStyle())
            .disabled(call.done)
        }
        .padding(.horizontal, 10).frame(height: 60)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(call.done ? 0.03 : 0.07)))
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: call.done)
    }
}
