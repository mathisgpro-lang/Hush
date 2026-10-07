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
    /// Like notifications on the lock screen (Mathis): one quest in front, the others stacked behind it; swipe up to
    /// fan them out into the full list, swipe down to gather them again.
    @State private var expanded = false
    @GestureState private var drag: CGFloat = 0

    private var left: Int { calls.filter { !$0.done }.count }
    private static let rowH: CGFloat = 56, gap: CGFloat = 8, peek: CGFloat = 9

    var body: some View {
        let n = calls.count
        let stackH = n == 0 ? Self.rowH : expanded ? CGFloat(n) * Self.rowH + CGFloat(max(0, n - 1)) * Self.gap
                                              : Self.rowH + CGFloat(min(2, max(0, n - 1))) * Self.peek
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 8) {
                Text(left == 0 ? (calls.isEmpty ? "Your day is ready" : "All done today") : left == 1 ? "1 quest left" : "\(left) quests left")
                    .font(.story(16, .medium)).foregroundStyle(Theme.cream)
                Spacer()
                if n > 1 {
                    Button { withAnimation(Motion.soft) { expanded.toggle() } } label: {
                        HStack(spacing: 4) {
                            Text(expanded ? "Less" : "\(n - 1) more").font(.ui(12, .semibold))
                            Image(systemName: expanded ? "chevron.down" : "chevron.up").font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(Theme.cream.opacity(0.85))
                        .padding(.horizontal, 10).frame(height: 28)
                        .background(Capsule().fill(.white.opacity(0.1)))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(PressableStyle())
                }
                Button(action: add) {
                    Image(systemName: "plus").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.cream)
                        .frame(width: 28, height: 28).background(Circle().fill(.white.opacity(0.1)))
                        .contentShape(Circle())
                }
                .buttonStyle(PressableStyle())
            }
            .padding(.horizontal, 4)
            if calls.isEmpty {
                Button(action: add) {
                    Text("Choose today's quests").font(.story(16)).foregroundStyle(Theme.cream.opacity(0.85))
                        .frame(maxWidth: .infinity).frame(height: Self.rowH)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.champagne.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                }
            } else {
                ZStack(alignment: .top) {
                    ForEach(Array(calls.enumerated()), id: \.element.id) { i, c in
                        let behind = !expanded && i > 0
                        QuestRow(call: c, open: { open(c) }, tick: { p in tick(c, p) })
                            .brightness(behind ? -0.06 * Double(min(i, 2)) : 0)
                            .scaleEffect(x: behind ? 1 - CGFloat(min(i, 2)) * 0.05 : 1, y: 1)
                            .offset(y: expanded ? CGFloat(i) * (Self.rowH + Self.gap) : CGFloat(min(i, 2)) * Self.peek)
                            .opacity(behind ? (i <= 2 ? 1 - Double(i) * 0.25 : 0) : 1)
                            .zIndex(Double(-i))
                            .allowsHitTesting(!behind)
                    }
                }
                .frame(height: stackH + (expanded ? 0 : max(0, -drag) * 0.25), alignment: .top)
                .overlay(alignment: .bottom) {
                    if !expanded && n > 1 {                          // tap the stack to open it too
                        Color.clear.frame(height: 22).contentShape(Rectangle())
                            .onTapGesture { withAnimation(Motion.soft) { expanded = true } }
                    }
                }
            }
        }
        .padding(.horizontal, 2)
        .contentShape(Rectangle())
        .highPriorityGesture(DragGesture(minimumDistance: 14)
            .updating($drag) { v, st, _ in st = v.translation.height }
            .onEnded { v in
                let dy = v.translation.height + (v.predictedEndTranslation.height - v.translation.height) * 0.3
                if dy < -30, !expanded { UIImpactFeedbackGenerator(style: .soft).impactOccurred(); withAnimation(Motion.soft) { expanded = true } }
                else if dy > 30, expanded { withAnimation(Motion.soft) { expanded = false } }
            })
        .animation(Motion.soft, value: calls.map(\.done))
        .animation(.interactiveSpring, value: drag)
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
                        Circle().fill(call.realm.color.opacity(0.22)).frame(width: 38, height: 38)
                        Image(uiImage: UIImage(named: "\(call.prop).png") ?? UIImage()).resizable().scaledToFit().frame(width: 28, height: 28)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(call.title).font(.story(17, .semibold)).foregroundStyle(Theme.ink.opacity(call.done ? 0.4 : 1))
                            .strikethrough(call.done, color: Theme.ink.opacity(0.4)).lineLimit(1)
                        HStack(spacing: 6) {
                            Text(call.counted && !call.done ? "\(call.progress)/\(call.target) \(call.unit)" : "\(call.minutes) min")
                            Text("·")
                            HStack(spacing: 3) { EmberCoin(size: 11); Text("+10") }
                        }
                        .font(.ui(13, .semibold)).foregroundStyle(Theme.ink.opacity(call.done ? 0.35 : 0.65))
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
                        .fill(call.done ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 0.78, blue: 0.4), Color(red: 0.93, green: 0.55, blue: 0.22)], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Color.white))
                    RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(call.done ? .clear : Theme.paperEdge.opacity(0.55), lineWidth: 1.2)
                    Image(systemName: "checkmark").font(.system(size: 19, weight: .heavy))
                        .foregroundStyle(call.done ? .white : Color(red: 0.42, green: 0.62, blue: 0.3))
                        .scaleEffect(call.done ? 1.1 : 1)
                }
                .frame(width: 46, height: 40)
                .background(GeometryReader { g in Color.clear.onAppear { tickCenter = CGPoint(x: g.frame(in: .global).midX, y: g.frame(in: .global).midY) }
                    .onChange(of: g.frame(in: .global)) { _, f in tickCenter = CGPoint(x: f.midX, y: f.midY) } })
            }
            .buttonStyle(PressableStyle())
            .disabled(call.done)
        }
        .padding(.horizontal, 8).frame(height: 56)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(LinearGradient(colors: [Color(red: 1, green: 0.98, blue: 0.93), Theme.paperTop], startPoint: .top, endPoint: .bottom))
            .opacity(call.done ? 0.82 : 1))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.paperEdge.opacity(0.35), lineWidth: 0.75))
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: call.done)
    }
}
