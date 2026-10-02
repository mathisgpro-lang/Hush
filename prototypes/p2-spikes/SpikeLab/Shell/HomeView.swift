// Home, the cockpit (decision 105): your Flame on the stone circle, today's calls floating by the hearth like the
// UI kit (style anchor), the light flying from a finished call to your Flame, and a clear bar: the World, the Book,
// your Flame. A hint always points to where something new waits.
import SwiftUI
import RealityKit

struct HomeView: View {
    let model: ShellModel
    @State private var scene = SanctuaryScene()
    @State private var meter = FrameMeter()
    @State private var director: AliveDirector?
    @State private var open: Call?
    @State private var strand: (from: CGPoint, t: CGFloat)?
    @State private var toast: String?
    @State private var dragStartPan: SIMD2<Float>?

    // Where the calls float (fractions of the screen), around the circle like the UI kit.
    private let slots: [CGPoint] = [CGPoint(x: 0.3, y: 0.3), CGPoint(x: 0.72, y: 0.335), CGPoint(x: 0.5, y: 0.6)]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                RealityView { content in
                    content.camera = .virtual
                    do { try await scene.build() } catch { print("SCENE BUILD FAILED:", error); return }
                    content.add(scene.root)
                    scene.setVitality(1)
                    let d = AliveDirector(seed: 5, meter: meter)
                    d.attach(scene.hero, tempo: 0.55)
                    director = d
                    scene.updates = content.subscribe(to: SceneEvents.Update.self) { e in scene.update(dt: Float(e.deltaTime)) }
                }
                .ignoresSafeArea()
                .onTapGesture { director?.tapped() }
                .simultaneousGesture(lookAround(geo.size))

                // Today's calls by the hearth: they stay with the world when you look around.
                TimelineView(.animation) { _ in
                    let shift = CGFloat(-scene.pan.x) * ppm(geo.size), lift = CGFloat(scene.pan.y) * ppm(geo.size)
                    ZStack {
                        ForEach(Array(model.calls.enumerated()), id: \.element.id) { i, call in
                            if !call.done {
                                CallTag(call: call)
                                    .position(x: slots[i].x * geo.size.width + shift, y: slots[i].y * geo.size.height + lift)
                                    .onTapGesture { withAnimation(.spring(duration: 0.4)) { open = call } }
                                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                            }
                        }
                    }
                }

                // The light flying from a finished call to your Flame.
                if let s = strand {
                    let to = CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.47)
                    let p = CGPoint(x: s.from.x + (to.x - s.from.x) * s.t, y: s.from.y + (to.y - s.from.y) * s.t - sin(s.t * .pi) * 80)
                    Circle().fill(RadialGradient(colors: [.white, Color(red: 1, green: 0.8, blue: 0.4), .clear], center: .center, startRadius: 1, endRadius: 22))
                        .frame(width: 44, height: 44).position(p).allowsHitTesting(false)
                }

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    if let toast { Text(toast).font(.system(size: 14, design: .serif)).padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(.black.opacity(0.6))).foregroundStyle(.white).transition(.opacity).padding(.bottom, 8) }
                    hint
                    cockpitBar
                }
                .padding(.horizontal, 16)

                if let call = open { card(call, size: geo.size) }
            }
        }
        .onAppear { meter.start() }
        .onDisappear { meter.stop(); director?.stop() }
    }

    private func ppm(_ size: CGSize) -> CGFloat { size.height / CGFloat(SanctuaryScene.visibleHeight) * 0.98 }

    /// Drag to look around the Sanctuary, a little in any direction (Clash of Clans–style): past the limit the
    /// world resists like a rubber band, and letting go glides on (momentum), then settles back inside.
    private func lookAround(_ size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { v in
                if dragStartPan == nil { dragStartPan = scene.pan; scene.fingerDown = true }
                let raw = (dragStartPan ?? .zero) + SIMD2(-Float(v.translation.width), Float(v.translation.height)) / Float(ppm(size))
                scene.panTarget = SIMD2(rubber(raw.x, scene.panLimit.x), rubber(raw.y, scene.panLimit.y))
            }
            .onEnded { v in
                let projected = (dragStartPan ?? .zero) + SIMD2(-Float(v.predictedEndTranslation.width), Float(v.predictedEndTranslation.height)) / Float(ppm(size))
                scene.panTarget = simd_clamp(projected, -scene.panLimit, scene.panLimit)
                dragStartPan = nil; scene.fingerDown = false
            }
    }

    /// Past the limit, movement fades out smoothly (never more than ~5 cm beyond it): you feel the edge.
    private func rubber(_ x: Float, _ lim: Float) -> Float {
        let over = abs(x) - lim
        guard over > 0 else { return x }
        let k: Float = 0.05
        return (lim + k * (1 - exp(-over / k))) * (x < 0 ? -1 : 1)
    }

    private var topBar: some View {
        VStack(spacing: 4) {
            Text("Sanctuary").font(.system(size: 34, weight: .regular, design: .serif)).foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 6)
            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill").font(.caption)
                Text(model.light == 0 ? "Your day is ready" : "\(model.light) light sent into the world today")
                    .font(.system(size: 13, design: .serif))
            }
            .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.top, 8)
    }

    @ViewBuilder private var hint: some View {
        if let r = model.newHere.first {
            Button { withAnimation(.easeInOut(duration: 0.6)) { model.go(.map) } } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles").foregroundStyle(r.color)
                    Text("Something new waits in \(r.name)").font(.system(size: 14, design: .serif))
                    Image(systemName: "chevron.right").font(.caption)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(Capsule().fill(.black.opacity(0.55)))
                .overlay(Capsule().stroke(r.color.opacity(0.7), lineWidth: 1))
                .foregroundStyle(.white)
            }
            .padding(.bottom, 10)
        }
    }

    private var cockpitBar: some View {
        HStack(spacing: 0) {
            barButton("map.fill", "World", badge: !model.newHere.isEmpty) { withAnimation(.easeInOut(duration: 0.6)) { model.go(.map) } }
            barButton("book.closed.fill", "Book", badge: false) { flash("The Book of Your Flame opens after 10 days lived.") }
            barButton("flame.fill", "Your Flame", badge: false) { director?.tapped() }
        }
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(red: 0.08, green: 0.06, blue: 0.05).opacity(0.78)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(red: 1, green: 0.7, blue: 0.35).opacity(0.35), lineWidth: 1))
        .padding(.bottom, 4)
    }

    private func barButton(_ symbol: String, _ label: String, badge: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: symbol).font(.system(size: 22))
                    if badge { Circle().fill(Color(red: 1, green: 0.55, blue: 0.2)).frame(width: 10, height: 10).offset(x: 6, y: -3) }
                }
                Text(label).font(.system(size: 12, design: .serif))
            }
            .frame(maxWidth: .infinity).foregroundStyle(Color(red: 1, green: 0.88, blue: 0.7))
        }
    }

    private func card(_ call: Call, size: CGSize) -> some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.25).ignoresSafeArea().onTapGesture { withAnimation { open = nil } }
            VStack(spacing: 10) {
                HStack { Spacer(); Button { withAnimation { open = nil } } label: { Image(systemName: "xmark.circle").font(.title2) } }
                Image(systemName: call.symbol).font(.system(size: 28)).foregroundStyle(call.realm.color)
                Text(call.title).font(.system(size: 26, design: .serif))
                Text(call.detail).font(.system(size: 15, design: .serif)).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.8))
                Text("Light goes to \(call.realm.name)").font(.caption).foregroundStyle(call.realm.color.opacity(0.9))
                Button { finish(call, size: size) } label: {
                    Text("I did it").font(.system(size: 18, design: .serif)).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Capsule().fill(LinearGradient(colors: [Color(red: 0.45, green: 0.55, blue: 0.2), Color(red: 0.3, green: 0.4, blue: 0.12)], startPoint: .top, endPoint: .bottom)))
                        .overlay(Capsule().stroke(Color(red: 0.9, green: 0.85, blue: 0.5).opacity(0.6), lineWidth: 1))
                }
            }
            .foregroundStyle(.white).padding(20)
            .background(RoundedRectangle(cornerRadius: 26).fill(Color(red: 0.12, green: 0.14, blue: 0.08).opacity(0.94)))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color(red: 0.8, green: 0.75, blue: 0.4).opacity(0.5), lineWidth: 1))
            .padding(.horizontal, 18).padding(.bottom, 30)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func finish(_ call: Call, size: CGSize) {
        let i = model.calls.firstIndex(where: { $0.id == call.id }) ?? 0
        let from = CGPoint(x: slots[i].x * size.width, y: slots[i].y * size.height)
        withAnimation { open = nil }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(duration: 0.4)) { model.complete(call.id) }
        strand = (from, 0)
        Task { @MainActor in
            for k in 1...36 { try? await Task.sleep(for: .milliseconds(25)); strand = (from, CGFloat(k) / 36) }
            strand = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            director?.actionCompleted(call.realm == .grove ? .heart : call.realm == .library ? .mind : call.realm == .highlands ? .body : .spirit)
        }
    }

    private func flash(_ s: String) {
        withAnimation { toast = s }
        Task { @MainActor in try? await Task.sleep(for: .seconds(2.4)); withAnimation { toast = nil } }
    }
}

/// A call as a glowing scroll tag (UI kit style anchor).
struct CallTag: View {
    let call: Call
    @State private var bob = false
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: call.symbol).font(.system(size: 13)).foregroundStyle(call.realm.color)
            Text(call.title).font(.system(size: 14, design: .serif)).foregroundStyle(.white)
        }
        .padding(.horizontal, 13).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.07, green: 0.09, blue: 0.06).opacity(0.82)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(call.realm.color.opacity(0.8), lineWidth: 1.2))
        .shadow(color: call.realm.color.opacity(0.55), radius: 8)
        .offset(y: bob ? -3 : 3)
        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: bob)
        .onAppear { bob = true }
    }
}
