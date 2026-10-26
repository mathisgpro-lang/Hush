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
    /// The XP a quest will bring (shown on its card, like the Embers).
    var xpOf: (Call) -> Int = { _ in 0 }
    /// The quest floor shows every quest as a list (decision 157); the stack is for small spaces.
    var alwaysOpen = false
    /// (Quest floor) the list is shown, or folded down to its header (Mathis: the toggle is back).
    var sheetUp = true
    var toggleSheet: () -> Void = {}
    /// Like notifications on the lock screen (Mathis): one quest in front, the others stacked behind it; swipe up to
    /// fan them out into the full list, swipe down to gather them again.
    @State private var expanded = false
    @GestureState private var drag: CGFloat = 0

    private var left: Int { calls.filter { !$0.done }.count }
    /// The panel shows the day's four quests at once, no scrolling (Mathis, 2026-10-22; it was three, 2026-10-14);
    /// only quests added beyond four are a scroll away.
    private static let visible = 4
    private static let rowH: CGFloat = 60, gap: CGFloat = 8, peek: CGFloat = 9   // sleek cards (Mathis, 2026-10-14)
    private var rowHeight: CGFloat { Self.rowH }
    private var rowGap: CGFloat { Self.gap }

    var body: some View {
        let n = calls.count
        let stackH = n == 0 ? Self.rowH : expanded ? CGFloat(n) * Self.rowH + CGFloat(max(0, n - 1)) * Self.gap
                                              : Self.rowH + CGFloat(min(2, max(0, n - 1))) * Self.peek
        VStack(alignment: .leading, spacing: sheetUp || !alwaysOpen ? 9 : 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(left == 0 ? (calls.isEmpty ? "Your day is ready" : "Your Flame feels good today") : "Your Flame needs today")
                    .font(.story(16.5, .medium)).foregroundStyle(Theme.cream)
                Spacer()
                if n > 1 && !alwaysOpen {
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
                if alwaysOpen && !calls.isEmpty {                       // fold the list away, or bring it back
                    Button(action: toggleSheet) {
                        Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.cream)
                            .rotationEffect(.degrees(sheetUp ? 0 : 180))
                            .frame(width: 28, height: 28).background(Circle().fill(.white.opacity(0.1))).contentShape(Circle())
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
            } else if alwaysOpen && !sheetUp {
                EmptyView()                                          // folded: just the header
            } else if alwaysOpen {
                ScrollViewReader { reader in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: rowGap) {
                            ForEach(calls) { c in QuestRow(call: c, xp: xpOf(c), open: { open(c) }, tick: { p in tick(c, p) }).id(c.id) }
                        }
                        .padding(.bottom, 4)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .task {                                                // (test: -scrolltest scrolls the list by itself)
                        guard CommandLine.arguments.contains("-scrolltest"), calls.count > Self.visible else { return }
                        try? await Task.sleep(for: .seconds(6))
                        for k in 0..<40 {
                            withAnimation(.easeInOut(duration: 0.6)) { reader.scrollTo(k.isMultiple(of: 2) ? calls.last?.id : calls.first?.id) }
                            try? await Task.sleep(for: .milliseconds(800))
                        }
                    }
                }
                // As tall as four quests at most (then it scrolls): the sheet hugs them, right above the bar.
                .frame(height: CGFloat(min(n, Self.visible)) * rowHeight + CGFloat(max(0, min(n, Self.visible) - 1)) * rowGap + 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                ZStack(alignment: .top) {
                    ForEach(Array(calls.enumerated()), id: \.element.id) { i, c in
                        let behind = !expanded && i > 0
                        QuestRow(call: c, xp: xpOf(c), open: { open(c) }, tick: { p in tick(c, p) })
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
            }, including: alwaysOpen ? .subviews : .all)          // (the list scrolls instead)
        .animation(Motion.soft, value: calls.map(\.done))
        .animation(.interactiveSpring, value: drag)
    }
}

struct QuestRow: View {
    let call: Call
    var xp: Int = 0                       // the XP it brings (no per-quest streaks: one streak, yours, Mathis 2026-10-15)
    let open: () -> Void
    let tick: (CGPoint) -> Void
    /// Where the tick sits on screen, kept outside SwiftUI's state: it changes on every frame of a scroll, and as state
    /// it redrew every card on every frame (the scroll felt laggy). Read only when the tick is tapped.
    @State private var tickSpot = PointBox()
    @State private var pressed = false
    @State private var popped = 0          // bumps when the quest is done: the tick pops, a ring ripples, the card bounces

    var body: some View {
        let _ = ScreenFPS.on ? ScreenFPS.shared.rowBodies += 1 : ()
        HStack(spacing: 10) {
            Button(action: open) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(call.realm.color.opacity(0.22)).frame(width: 42, height: 42)
                        Image(uiImage: UIImage(named: "\(call.prop).png") ?? UIImage(named: "\(call.prop.replacingOccurrences(of: "px-", with: "")).png") ?? UIImage()).resizable().interpolation(.none).scaledToFit().frame(width: 30, height: 30)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(call.title).font(.story(17, .semibold)).foregroundStyle(Theme.ink.opacity(call.done ? 0.4 : 1))
                            .strikethrough(call.done, color: Theme.ink.opacity(0.4)).lineLimit(1)
                        HStack(spacing: 6) {
                            // An intention: your way, or the idea you picked (decision 166).
                            Text(call.pillar != nil ? (call.idea.map { "Idea: \($0)" } ?? "Your way") : call.counted && !call.done ? "\(call.progress)/\(call.target) \(call.unit)" : "\(call.minutes) min")
                                .lineLimit(1)
                            Text("·")
                            HStack(spacing: 2) { Image(systemName: "sparkle").font(.system(size: 9, weight: .bold)); Text("+\(xp) XP") }
                                .foregroundStyle(Theme.accent)
                            Text("·")
                            HStack(spacing: 3) { EmberCoin(size: 11); Text("+10") }
                        }
                        .font(.ui(12, .semibold)).foregroundStyle(Theme.ink.opacity(call.done ? 0.35 : 0.65))
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(CardPress())
            // The tick: one tap and it's done.
            Button {
                guard !call.done else { return }
                tick(tickSpot.p)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(call.done ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 0.78, blue: 0.4), Color(red: 0.93, green: 0.55, blue: 0.22)], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Color.white))
                    RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(call.done ? .clear : Theme.paperEdge.opacity(0.55), lineWidth: 1.2)
                    Image(systemName: "checkmark").font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(call.done ? .white : Color(red: 0.42, green: 0.62, blue: 0.3))
                        .scaleEffect(call.done ? 1.1 : 1)
                }
                .frame(width: 46, height: 40)
                .keyframeAnimator(initialValue: CGFloat(1), trigger: popped) { v, s in v.scaleEffect(s) } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(0.82, duration: 0.07)
                        SpringKeyframe(1.28, duration: 0.16, spring: .snappy)
                        SpringKeyframe(1, duration: 0.4, spring: .bouncy)
                    }
                }
                .background {                                     // a golden ring ripples out of the tick
                    Circle().stroke(Theme.gold, lineWidth: 3)
                        .keyframeAnimator(initialValue: Ripple(), trigger: popped) { v, r in v.scaleEffect(r.scale).opacity(r.opacity) } keyframes: { _ in
                            KeyframeTrack(\.scale) { CubicKeyframe(0.6, duration: 0.01); CubicKeyframe(2.6, duration: 0.55) }
                            KeyframeTrack(\.opacity) { CubicKeyframe(0.9, duration: 0.01); CubicKeyframe(0, duration: 0.55) }
                        }
                        .allowsHitTesting(false)
                }
                .onGeometryChange(for: CGPoint.self) { CGPoint(x: $0.frame(in: .global).midX, y: $0.frame(in: .global).midY) } action: { tickSpot.p = $0 }
            }
            .buttonStyle(PressableStyle())
            .disabled(call.done)
        }
        .padding(.leading, 9).padding(.trailing, 10).frame(height: 60)
        .keyframeAnimator(initialValue: CGFloat(1), trigger: popped) { v, s in v.scaleEffect(s) } keyframes: { _ in
            KeyframeTrack { SpringKeyframe(1.035, duration: 0.14, spring: .snappy); SpringKeyframe(1, duration: 0.45, spring: .bouncy) }
        }
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(LinearGradient(colors: [Color(red: 1, green: 0.98, blue: 0.93), Theme.paperTop], startPoint: .top, endPoint: .bottom))
            .opacity(call.done ? 0.82 : 1))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.paperEdge.opacity(0.35), lineWidth: 0.75))
        // A crisp lip under the card instead of a soft shadow (after Finch): it costs nothing to draw, while blurred
        // shadows over the moving world cost half the frame rate (task 6).
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.black.opacity(0.28)).offset(y: 3))
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: call.done)
        .onChange(of: call.done) { _, done in if done { popped += 1 } }
    }
}

/// The ring's two values over time.
private struct Ripple { var scale: CGFloat = 0.6; var opacity: Double = 0 }

/// A card under the finger: it sinks a touch and brightens, then springs back (task 5: taps you can feel).
struct CardPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? 0.03 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, down in if down { Haptic.touch() } }
    }
}

/// Inside a daily intention (decision 166): your own way counts; if you don't know where to start, your Flame offers
/// three ideas at your level (they climb slowly with the days you keep this pillar), or picks one for you.
struct IntentionIdeas: View {
    let ideas: [QuestDef]
    let picked: String?
    let ink: Color, tint: Color
    let pick: (String?) -> Void
    @State private var open = false
    var body: some View {
        VStack(spacing: 8) {
            if !open && picked == nil {
                Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { open = true } } label: {
                    HStack(spacing: 6) { Image(systemName: "sparkles"); Text("Need an idea?") }
                        .font(.story(16, .medium)).foregroundStyle(ink)
                        .padding(.horizontal, 18).frame(height: 40)
                        .background(Capsule().fill(tint.opacity(0.18))).overlay(Capsule().stroke(tint.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(PressableStyle())
            } else {
                Text("Ideas from your Flame").font(.story(14, .medium)).foregroundStyle(ink.opacity(0.7))
                ForEach(ideas) { q in
                    Button { pick(picked == q.title ? nil : q.title) } label: { ParchmentChoice(text: q.title, selected: picked == q.title) }
                        .buttonStyle(PressableStyle())
                }
                if let q = ideas.first(where: { $0.title == picked }) {
                    Text(q.detail).font(.ui(13)).multilineTextAlignment(.center).foregroundStyle(ink.opacity(0.75)).fixedSize(horizontal: false, vertical: true)
                    Text(q.why).font(.story(13).italic()).multilineTextAlignment(.center).foregroundStyle(ink.opacity(0.6)).fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    let others = ideas.filter { $0.title != picked }
                    if let q = others.randomElement() { pick(q.title) }
                } label: {
                    HStack(spacing: 5) { Image(systemName: "dice.fill"); Text(picked == nil ? "Choose for me" : "Another one") }
                        .font(.ui(14, .semibold)).foregroundStyle(ink.opacity(0.75))
                }
                .buttonStyle(PressableStyle()).padding(.top, 2)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

/// A point that can change without redrawing anything (see QuestRow.tickSpot).
final class PointBox { var p: CGPoint = .zero }

