// Inside a world (decision 105): the Whispering Grove with your Flame on the stone circle, glowing spots to explore
// (tap: the camera glides there and the spot tells its story), a clear way back to the map. The Grove restores from
// your Heart light (S3).
import SwiftUI
import RealityKit

struct Spot: Identifiable {
    let id: String, title: String, line: String, symbol: String
    let uv: SIMD2<Float>            // in the painting (v up)
    var action: String? = nil
}

let groveSpots: [Spot] = [
    Spot(id: "circle", title: "The Gathering", line: "Every week, lights gather here. This week's Gathering: tell someone why you're grateful for them.", symbol: "circle.hexagongrid.fill", uv: [0.36, 0.3], action: "Join this week's Gathering"),
    Spot(id: "tree", title: "Your Journey", line: "Lanterns for the Ones You Love. Each kind word relights a lantern in these old trees.", symbol: "lamp.desk.fill", uv: [0.2, 0.6], action: "Send a lantern (a real Heart action)"),
    Spot(id: "twins", title: "Nim & Ro", line: "\"You came back!\" \"We knew you would.\" The twins keep the Grove's counsel, with sources, never lectures.", symbol: "sparkles", uv: [0.78, 0.47]),
    Spot(id: "pool", title: "The quiet pool", line: "The water remembers every lantern you've lit. It moves again as the Grove wakes.", symbol: "drop.fill", uv: [0.62, 0.21]),
]

struct RealmView: View {
    let model: ShellModel
    let realm: RealmID
    @State private var scene = GroveScene()
    @State private var meter = FrameMeter()
    @State private var director: AliveDirector?
    @State private var focused: Spot?
    @State private var ready = false
    @State private var appear = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                RealityView { content in
                    content.camera = .virtual
                    do { try await scene.build() } catch { return }
                    content.add(scene.root)
                    scene.heartDepth = 6                      // prototype: a Grove that has started to wake
                    let d = AliveDirector(seed: 9, meter: meter)
                    d.attach(scene.hero, tempo: 0.55)
                    director = d
                    scene.updates = content.subscribe(to: SceneEvents.Update.self) { e in scene.update(dt: Float(e.deltaTime)) }
                    withAnimation(.easeOut(duration: 0.8)) { ready = true }
                }
                .ignoresSafeArea()
                .scaleEffect(appear ? 1 : 1.25)
                .onTapGesture { if focused == nil { director?.tapped() } else { unfocus() } }

                if ready && focused == nil {
                    ForEach(groveSpots) { s in
                        SpotMarker(spot: s)
                            .position(x: (0.5 + CGFloat(s.uv.x - 0.5) * 1.08) * geo.size.width,
                                      y: (0.5 - CGFloat(s.uv.y - 0.5) * 1.08) * geo.size.height)
                            .onTapGesture { focus(s) }
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                VStack {
                    header
                    Spacer()
                    if let s = focused { spotCard(s) } else if ready { footer }
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear { meter.start(); withAnimation(.easeOut(duration: 1.0)) { appear = true } }
        .onDisappear { meter.stop(); director?.stop() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            Button { back() } label: {
                Label("Map", systemImage: "map.fill").font(.system(size: 15, design: .serif))
                    .padding(.horizontal, 14).padding(.vertical, 9).background(Capsule().fill(.black.opacity(0.55))).foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(realm.name).font(.system(size: 20, design: .serif)).foregroundStyle(.white)
                let level = Restoration.level(depth: scene.heartDepth)
                Text("\(realm.pillar) · \(Restoration.names[level]) · \(scene.litCount) lanterns lit")
                    .font(.system(size: 12, design: .serif)).foregroundStyle(realm.color)
            }
            .padding(.horizontal, 14).padding(.vertical, 8).background(RoundedRectangle(cornerRadius: 16).fill(.black.opacity(0.5)))
        }
        .padding(.top, 4)
    }

    private var footer: some View {
        Text("Tap a glowing spot to explore")
            .font(.system(size: 14, design: .serif)).foregroundStyle(.white.opacity(0.85))
            .padding(.horizontal, 16).padding(.vertical, 9).background(Capsule().fill(.black.opacity(0.5)))
            .padding(.bottom, 30)
    }

    private func spotCard(_ s: Spot) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: s.symbol).foregroundStyle(realm.color)
                Text(s.title).font(.system(size: 22, design: .serif))
                Spacer()
                Button { unfocus() } label: { Image(systemName: "xmark.circle").font(.title2) }
            }
            Text(s.line).font(.system(size: 15, design: .serif)).foregroundStyle(.white.opacity(0.85)).frame(maxWidth: .infinity, alignment: .leading)
            if let a = s.action {
                Button {
                    scene.act()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    unfocus()
                } label: {
                    Text(a).font(.system(size: 16, design: .serif)).frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(Capsule().fill(realm.color.opacity(0.35))).overlay(Capsule().stroke(realm.color, lineWidth: 1))
                }
            }
        }
        .foregroundStyle(.white).padding(18)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(red: 0.07, green: 0.06, blue: 0.08).opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(realm.color.opacity(0.5), lineWidth: 1))
        .padding(.bottom, 24)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func focus(_ s: Spot) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        scene.focus = scene.spot(s.uv.x, s.uv.y)
        scene.hero.look(at: [s.uv.x < 0.5 ? -0.7 : 0.7, s.uv.y > 0.36 ? 0.5 : -0.3])
        withAnimation(.spring(duration: 0.5)) { focused = s }
    }

    private func unfocus() {
        scene.focus = nil
        scene.hero.look(at: nil)
        withAnimation(.spring(duration: 0.5)) { focused = nil }
    }

    private func back() {
        unfocus()
        withAnimation(.easeIn(duration: 0.4)) { appear = false }
        withAnimation(.easeInOut(duration: 0.6)) { model.go(.map) }
    }
}

/// A glowing, gently pulsing spot to explore.
struct SpotMarker: View {
    let spot: Spot
    @State private var pulse = false
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().fill(Color(red: 1, green: 0.85, blue: 0.5).opacity(0.25)).frame(width: pulse ? 46 : 34)
                Circle().fill(Color(red: 1, green: 0.85, blue: 0.55)).frame(width: 14).shadow(color: .orange, radius: 8)
            }
            .frame(width: 48, height: 48)
            Text(spot.title).font(.system(size: 12, weight: .semibold, design: .serif))
                .padding(.horizontal, 8).padding(.vertical, 3).background(Capsule().fill(.black.opacity(0.55))).foregroundStyle(.white)
        }
        .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
    }
}
