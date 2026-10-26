// The daily screen (decision 183, plan docs/plan-2.0/p33-daily-welcome.md), built to Codex's approved sketch
// (docs/design/p33/daily-morning.png). The first open of each day: your live Flame big and centred in a warm light, the
// streak, the week, one honest line, three bars sliding right from where you were 7 days ago, the day's "why", and
// "Let's go" collecting the daily pouch. Coming to the app lights the day (decision 184, Mathis): the number ticks up,
// today's box catches fire and a new form is revealed when one is reached. A short lit version comes back for the quest
// that repairs a missed day. The numbers come from DailyReport.
// Drawn without blurred shadows over large areas (decision 165): glows are painted gradients, cards have a crisp lip.
import SwiftUI
import RealityKit

extension Journey {
    /// The daily screen's numbers now; or just before the last quest; or just before today's first open.
    func dailyReport(pouch: Int = 0, beforeLastQuest: Bool = false, beforeToday: Bool = false) -> DailyReport {
        let cal = Calendar.current
        return DailyReport.make(deeds: beforeLastQuest ? Array(deeds.dropLast()) : deeds,
                                checkIns: beforeToday ? checkIns.filter { !cal.isDateInToday($0) } : checkIns,
                                xpBase: xpBase, pouch: pouch)
    }
}

/// What the daily screen is showing, fixed the moment it happened (a quick second quest or midnight can't change it).
struct DailyShow: Hashable {
    /// The numbers before this moment (the morning: before today's first open; lit: before the quest) and after it.
    var before: DailyReport
    var after: DailyReport
    /// The form on screen before any reveal (never the new one).
    var from: Evolution
    var evolvedTo: Evolution? = nil
    var milestone: Int? = nil
    /// The morning screen (bars, quote, "Let's go"); false: the short lit one after the quest that repaired a missed day.
    var full = true
}

// MARK: - The Flame on its own small stage (alive, never a picture: decision 93)

@MainActor final class DailyFlameStage {
    let root = Entity(), camera = PerspectiveCamera()
    private var hero: HeroRig?
    private var form: Evolution = .spark
    private var preparing: Task<Void, Never>?
    var updates: EventSubscription?
    private var blinkIn: Float = 2.5

    /// Builds the Flame (once) and shows `form`, while the app is still loading, so the screen opens with it there.
    func prepare(form f: Evolution) {
        let previous = preparing
        preparing = Task { @MainActor in
            await previous?.value
            await self.show(f)
        }
    }
    /// The moment waits for its Flame.
    func waitReady() async { await preparing?.value }
    /// …and for its first frames on screen (a new 3D view takes a moment to draw), so nothing rises in without it.
    func waitDrawn() async {
        var n = 0
        while frames < 2 && n < 75 { try? await Task.sleep(for: .milliseconds(40)); n += 1 }
    }

    private func show(_ f: Evolution) async {
        if hero == nil {
            let h = HeroRig(base: f.base, footInset: 0.045, reflection: false, glows: false, wander: 0)
            do { try await h.build() } catch { return }
            h.stationary = true
            h.hour = 13                                  // the painting's own daylight colours
            root.addChild(h.leanPivot)
            camera.camera.fieldOfViewInDegrees = 34
            camera.look(at: [0, 0.106, 0], from: [0, 0.108, 0.385], relativeTo: nil)
            root.addChild(camera)
            hero = h
        }
        form = f
        await hero?.switchForm(base: f.base, growth: f.growth)       // the rig builds at the Spark's size: its own form's size
        fit()
        hero?.setMood(0.8, season: .longLight, timeOfDay: .day)
    }
    /// Every form stands the same way on its stage, bigger forms a little bigger, with room above the fire's tips: the
    /// rig makes a form 0.27 × `growth` tall; this brings it to 0.172 × (1 + 30% of its growth), from the Spark (0.172)
    /// to Beyond (0.206), under a view 0.236 tall (Codex review, 2026-10-20: the Spark's crown was cut off).
    private func fit() {
        let g = form.growth
        hero?.leanPivot.scale = .init(repeating: 0.172 * (1 + (g - 1) * 0.3) / (0.27 * g))
    }
    /// Frames drawn since its current 3D view opened (and, -perf, how long they took).
    private var frames = 0
    var opened: CFTimeInterval = 0
    func newView() { frames = 0 }
    func update(_ dt: Float) {
        guard let hero else { return }
        frames += 1
        // This 3D view only redraws when something in it changes: a camera move far too small to see keeps it drawing
        // every frame, so the fire never freezes (alive, always: decision 93).
        camera.position.z = 0.385 + (frames.isMultiple(of: 2) ? 0 : 0.00001)
        if CommandLine.arguments.contains("-perf"), [1, 10, 30].contains(frames) {
            print(String(format: "DAILY frame %d at %.0f ms after the screen opened", frames, (CACurrentMediaTime() - opened) * 1000))
        }
        blinkIn -= dt
        if blinkIn < 0 { hero.blink(); blinkIn = Float.random(in: 2.6...5.5) }
        hero.update(dt: dt)
    }
    func become(_ f: Evolution) async {
        form = f
        await hero?.switchForm(base: f.base, growth: f.growth)
        fit()
        hero?.setMood(0.8, season: .longLight, timeOfDay: .day)
        hero?.react(.cheer)
    }
    func cheer() { hero?.react(.cheer) }
}

struct DailyFlameView: View {
    let stage: DailyFlameStage
    var interactive = true
    var body: some View {
        RealityView { content in
            content.camera = .virtual
            stage.opened = CACurrentMediaTime(); stage.newView()
            await stage.waitReady()                      // prepared during the launch (ShellModel)
            content.add(stage.root)
            stage.updates = content.subscribe(to: SceneEvents.Update.self) { e in stage.update(Float(e.deltaTime)) }
        }
        .contentShape(Rectangle())
        .onTapGesture { stage.cheer() }                  // it reacts to touch at once
        .allowsHitTesting(interactive)
    }
}

// MARK: - Pieces

/// A bar that slides right: the pale part is where you were 7 days ago (with its tick), the bright part is this week.
struct GhostBar: View {
    let before: Double
    let fill: Double
    var height: CGFloat = 10
    var body: some View {
        GeometryReader { g in
            let W = g.size.width
            let b = W * CGFloat(min(1, max(0, before)))
            let w = fill > 0.001 ? max(height, W * CGFloat(min(1, max(0, fill)))) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.10))
                Capsule().fill(LinearGradient(colors: [Theme.champagne, Theme.gold], startPoint: .leading, endPoint: .trailing))
                    .overlay(alignment: .top) {
                        Capsule().fill(.white.opacity(0.35)).frame(height: max(1.5, height * 0.3))
                            .padding(.horizontal, height * 0.45).padding(.top, height * 0.14)
                    }
                    .frame(width: w)
                Capsule().fill(Color(red: 0.62, green: 0.53, blue: 0.42))          // the ghost: 7 days ago
                    .frame(width: b > 0.5 ? max(b, height) : 0)
                Circle().fill(RadialGradient(colors: [.white.opacity(0.9), Theme.gold.opacity(0.45), .clear],
                                             center: .center, startRadius: 0, endRadius: height * 0.9))
                    .frame(width: height * 1.8, height: height * 1.8)
                    .offset(x: w - height * 0.9)
                    .opacity(fill > 0.01 && fill < 0.995 ? 1 : 0)
                RoundedRectangle(cornerRadius: 1).fill(Theme.cream)                // the tick where you were
                    .frame(width: 2.5, height: height + 8)
                    .offset(x: b - 1.25)
                    .opacity(b > 0.5 ? 1 : 0)
            }
        }
        .frame(height: height)
    }
}

/// A number drawn as an outline (the 1 of a new flame, waiting to be lit).
struct OutlinedNumber: View {
    let text: String
    let size: CGFloat
    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let a = Double(i) / 12 * 2 * .pi
                Text(text).font(.num(size, .heavy)).foregroundStyle(Theme.champagne.opacity(0.9))
                    .offset(x: cos(a) * 2.2, y: sin(a) * 2.2)
            }
            Text(text).font(.num(size, .heavy)).foregroundStyle(.black).blendMode(.destinationOut)   // hollow inside
        }
        .compositingGroup()
    }
}

/// A form as a dark silhouette with a thin gold rim: the next form stays secret until you reach it (decision 169).
struct FormSilhouette: View {
    let form: Evolution
    var height: CGFloat = 40
    var body: some View {
        if let img = UIImage(named: form.base + "-keyed.png")?.withRenderingMode(.alwaysTemplate) {
            ZStack {
                Image(uiImage: img).resizable().scaledToFit().foregroundStyle(Theme.gold.opacity(0.85)).scaleEffect(1.07)
                Image(uiImage: img).resizable().scaledToFit().foregroundStyle(Color(red: 0.13, green: 0.08, blue: 0.06))
            }
            .frame(height: height)
        }
    }
}

/// The lit-day flame and the streak shield (Codex's painted icons; a drawn stand-in until they land).
private struct DayFlameIcon: View {
    var size: CGFloat = 26
    var body: some View {
        if let img = UIImage(named: "day-flame.png") { Image(uiImage: img).resizable().scaledToFit().frame(width: size, height: size) }
        else {
            Image(systemName: "flame.fill").font(.system(size: size * 0.8, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [Color(red: 1, green: 0.92, blue: 0.55), Theme.ember], startPoint: .top, endPoint: .bottom))
        }
    }
}
private struct ShieldIcon: View {
    var size: CGFloat = 28
    var body: some View {
        if let img = UIImage(named: "streak-shield.png") { Image(uiImage: img).resizable().scaledToFit().frame(width: size, height: size) }
        else {
            Image(systemName: "shield.lefthalf.filled").font(.system(size: size * 0.8, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [Theme.champagne, Theme.gold], startPoint: .top, endPoint: .bottom))
        }
    }
}

/// One day of the week row.
private struct DayCircle: View {
    let day: DailyReport.Day
    let pop: Int
    var body: some View {
        ZStack {
            switch day {
            case .lived, .repaired:
                Circle().fill(Color(red: 0.24, green: 0.14, blue: 0.08))
                Circle().stroke(Theme.gold.opacity(0.55), lineWidth: 1)
                DayFlameIcon(size: 26).opacity(day == .repaired ? 0.75 : 1)
            case .shielded:
                Circle().fill(Color(red: 0.16, green: 0.12, blue: 0.1))
                Circle().stroke(Theme.champagne.opacity(0.4), lineWidth: 1)
                ShieldIcon(size: 22)
            case .missed, .empty:
                Circle().fill(Color.black.opacity(0.28))
                Circle().stroke(Color.white.opacity(0.08), lineWidth: 1)
            case .future:
                Circle().fill(Color.black.opacity(0.18))
                Circle().stroke(Color.white.opacity(0.14), lineWidth: 1)
            case .today:
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { tl in               // waiting: a glowing ring that breathes
                    let k = 0.5 + 0.5 * sin(tl.date.timeIntervalSinceReferenceDate * 2.4)
                    ZStack {
                        Circle().fill(RadialGradient(colors: [Theme.gold.opacity(0.18 + 0.12 * k), .clear], center: .center, startRadius: 2, endRadius: 30))
                            .scaleEffect(1.35)
                        Circle().stroke(LinearGradient(colors: [Color(red: 1, green: 0.92, blue: 0.62), Theme.gold], startPoint: .top, endPoint: .bottom), lineWidth: 2.5)
                        Image(systemName: "sparkle").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.champagne)
                            .offset(x: 21, y: -19).opacity(0.4 + 0.6 * k)
                        Image(systemName: "sparkle").font(.system(size: 6, weight: .bold)).foregroundStyle(Theme.champagne)
                            .offset(x: -19, y: 20).opacity(1 - 0.6 * k)
                    }
                }
            case .todayLit:
                Circle().fill(RadialGradient(colors: [Theme.gold.opacity(0.5), .clear], center: .center, startRadius: 2, endRadius: 34)).scaleEffect(1.45)
                Circle().fill(Color(red: 0.3, green: 0.16, blue: 0.07))
                Circle().stroke(LinearGradient(colors: [Color(red: 1, green: 0.95, blue: 0.7), Theme.gold], startPoint: .top, endPoint: .bottom), lineWidth: 2.5)
                DayFlameIcon(size: 30)
                SparkBurst(trigger: pop, radius: 34, count: 10)
            }
        }
        .frame(width: 42, height: 42)
    }
}

/// One row of the growth card: icon, title, detail, its bar, and (for the next form) the silhouette at the bar's end.
private struct GrowthRow<Icon: View>: View {
    let bar: DailyReport.Bar
    let fill: Double
    var goal: Evolution? = nil
    var detailGold = false
    @ViewBuilder let icon: () -> Icon
    var body: some View {
        HStack(spacing: 14) {
            icon().frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(bar.title).font(.story(18, .semibold)).foregroundStyle(Theme.cream).lineLimit(1).minimumScaleFactor(0.8)
                    if let b = bar.badge {
                        Text(b).font(.ui(11, .heavy)).foregroundStyle(Theme.ink)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(Theme.champagne))
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    }
                    Spacer(minLength: 6)
                    Text(bar.detail).font(.ui(13, .bold)).foregroundStyle(detailGold ? Theme.gold : Theme.cream.opacity(0.78))
                        .lineLimit(1).minimumScaleFactor(0.92).layoutPriority(1)
                }
                GhostBar(before: bar.before, fill: fill)
            }
            if let goal { FormSilhouette(form: goal, height: 42).frame(width: 34) }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - The screen

struct DailyWelcome: View {
    let show: DailyShow
    let form: Evolution
    /// The live Flame, prepared while the app loads (ShellModel.dailyStage).
    let stage: DailyFlameStage
    /// The moment plays once this is true (the screen opens under the launch veil, so its Flame is warm when it lifts).
    var live = true
    /// Closes the screen; for the morning, where the pouch's coins start (nil: nothing to collect).
    let close: (CGPoint?) -> Void

    @State private var appeared = false
    @State private var numberIn = false
    @State private var shownStreak: Int
    @State private var weekShown = 0
    @State private var barsShown = 0
    @State private var fills: [Double]
    @State private var tailIn = false
    @State private var todayLit = false
    @State private var litPop = 0
    @State private var revealed = false           // a new form has appeared
    @State private var flash = 0.0
    @State private var finished = false
    @State private var run: Task<Void, Never>?
    @State private var buttonFrame: CGRect = .zero

    init(show: DailyShow, form: Evolution, stage: DailyFlameStage, live: Bool = true, close: @escaping (CGPoint?) -> Void) {
        self.show = show; self.form = form; self.stage = stage; self.live = live; self.close = close
        _shownStreak = State(initialValue: show.before.streak)
        _fills = State(initialValue: show.full ? [show.after.form.before, show.after.level.before, show.after.skill.before]
                                               : [show.before.form.now, 0, 0])
    }

    private var isLit: Bool { !show.full }
    private var report: DailyReport { show.after }
    private var before: DailyReport { show.before }
    private var evolvedTo: Evolution? { show.evolvedTo }
    private var milestone: Int? { show.milestone }
    /// The form on screen before any reveal (never the new one).
    private var shownForm: Evolution { show.from }
    /// Today lights in this moment (the morning's first open, or the quest that repaired a missed day).
    private var lights: Bool { report.week.contains(.todayLit) && !before.week.contains(.todayLit) }
    private var todayIndex: Int? { report.week.firstIndex { $0 == .today || $0 == .todayLit } }

    var body: some View {
        ZStack {
            Theme.floor.ignoresSafeArea()
            RadialGradient(colors: [Theme.gold.opacity(0.26), .clear], center: .init(x: 0.5, y: 0.2), startRadius: 10, endRadius: 360)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                flameArea
                numberBlock.padding(.top, 2)
                weekCard.padding(.top, 10)
                Text(storyLine).font(.story(16.5).italic()).foregroundStyle(Theme.cream.opacity(0.92))
                    .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.85)
                    .padding(.horizontal, 26).padding(.top, 10)
                    .opacity(weekShown >= 7 ? 1 : 0)
                    .id(storyLine)
                    .transition(.opacity)
                growthCard.padding(.top, 12)
                if !isLit {
                    Text(quote).font(.story(15).italic()).foregroundStyle(Theme.cream.opacity(0.75))
                        .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.85)
                        .padding(.horizontal, 30).padding(.top, 10)
                        .opacity(tailIn ? 1 : 0)
                }
                Spacer(minLength: 8)
                bottom
            }
            .padding(.horizontal, 16)
            Color.white.opacity(flash).ignoresSafeArea().allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { tapped() }
        .onAppear { if live { start() } }
        .onChange(of: live) { _, v in if v { start() } }
        .onDisappear { run?.cancel() }
    }

    // MARK: Parts

    private var flameArea: some View {
        ZStack {
            Color.clear.overlay {                                // a soft warm light behind it (no rays: Mathis, 2026-10-20)
                Circle().fill(RadialGradient(colors: [Theme.gold.opacity(revealed ? 0.42 : 0.24), .clear], center: .center, startRadius: 10, endRadius: 170))
                    .frame(width: 340, height: 340)
            }
            DailyFlameView(stage: stage)
                .background(alignment: .bottom) {                // its pool of light, always under its feet
                    Ellipse().fill(RadialGradient(colors: [Theme.gold.opacity(0.5), .clear], center: .center, startRadius: 2, endRadius: 110))
                        .frame(width: 230, height: 46).padding(.bottom, 4)
                }
                .frame(maxHeight: 250)                           // about the same size in every version (a taller area only adds air)
                .frame(maxHeight: .infinity, alignment: isLit ? .center : .bottom)
            if revealed {
                SparkBurst(trigger: litPop, color: Theme.champagne, radius: 150, count: 16)
                VStack {
                    Text("NEW FORM").font(.ui(12, .heavy)).tracking(2.5).foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10).padding(.vertical, 4).background(Capsule().fill(Theme.champagne))
                    Spacer()
                }
                .padding(.top, 6)
                .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: .infinity)
        .padding(.horizontal, -16)
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
    }

    @ViewBuilder private var numberBlock: some View {
        VStack(spacing: 0) {
            if revealed, let f = evolvedTo {
                // From the form it grew from: "Your Spark became a Flame" (never "Your Flame became a Flame").
                Text("Your \(shownForm.name) became a \(f.name)").font(.story(26, .semibold)).foregroundStyle(Theme.champagne)
                    .multilineTextAlignment(.center).padding(.bottom, 6)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
            if shownStreak == 0 {
                // No streak today (a comeback or the very first): the 1 waits to be lit.
                OutlinedNumber(text: "1", size: 88).frame(height: 92)
                Text(report.best > 0 ? "A NEW FLAME TODAY" : "YOUR FIRST FLAME TODAY")
                    .font(.story(24, .bold)).tracking(1.2).foregroundStyle(Theme.cream)
                if report.best > 0 || report.shields > 0 {
                    HStack(spacing: 12) {
                        if report.best > 0 {
                            Text("Best: \(report.best) days").font(.ui(13, .bold)).foregroundStyle(Theme.champagne)
                                .padding(.horizontal, 12).padding(.vertical, 4)
                                .background(Capsule().fill(Color.black.opacity(0.3))).overlay(Capsule().stroke(Theme.champagne.opacity(0.4), lineWidth: 1))
                        }
                        if report.shields > 0 {
                            HStack(spacing: 3) { ShieldIcon(size: 22); Text("\(report.shields)").font(.num(18, .heavy)).foregroundStyle(Theme.champagne) }
                        }
                    }
                    .padding(.top, 6)
                }
            } else {
                ZStack {
                    Text("\(shownStreak)").font(.num(revealed ? 62 : 90, .heavy)).foregroundStyle(Theme.warmShadow.opacity(0.9)).offset(y: 4)   // its lip
                    Text("\(shownStreak)").font(.num(revealed ? 62 : 90, .heavy))
                        .foregroundStyle(LinearGradient(colors: [Color(red: 1, green: 0.96, blue: 0.86), Theme.champagne], startPoint: .top, endPoint: .bottom))
                    SparkBurst(trigger: litPop, radius: 70, count: 12)
                    if lights && todayLit && !revealed {
                        Text("+1").font(.num(30, .heavy)).foregroundStyle(Theme.gold)
                            .offset(x: 78, y: -34)
                            .transition(.scale(scale: 0.3).combined(with: .opacity).combined(with: .offset(y: 16)))
                    }
                }
                .contentTransition(.numericText(value: Double(shownStreak)))
                .frame(height: revealed ? 66 : 92)
                HStack(spacing: 10) {
                    Text("DAY STREAK").font(.story(revealed ? 19 : 25, .bold)).tracking(1.4).foregroundStyle(Theme.cream)
                    if report.shields > 0 && !revealed {
                        HStack(spacing: 3) {
                            ShieldIcon(size: 26)
                            Text("\(report.shields)").font(.num(22, .heavy)).foregroundStyle(Theme.champagne)
                        }
                    }
                }
                .padding(.top, 0)
            }
        }
        .scaleEffect(numberIn ? 1 : 0.6)
        .opacity(numberIn ? 1 : 0)
    }

    private var weekCard: some View {
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 7) {
                    Text(letters[i]).font(.ui(13, i == todayIndex ? .heavy : .bold))
                        .foregroundStyle(i == todayIndex ? Theme.gold : Theme.cream.opacity(0.7))
                    DayCircle(day: dayShown(i), pop: litPop)
                        .scaleEffect(weekShown > i ? (lights && todayLit && i == todayIndex ? 1.12 : 1) : 0.4)
                        .opacity(weekShown > i ? 1 : 0)
                        .overlay(alignment: .bottom) {
                            if lights && todayLit && i == todayIndex {
                                Text("NOW LIT").font(.ui(10, .heavy)).tracking(0.8).foregroundStyle(Theme.gold)
                                    .fixedSize().offset(y: 16).transition(.opacity)
                            }
                        }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 10).padding(.bottom, lights ? 18 : 10).padding(.horizontal, 6)
        .background(card(22))
    }

    /// Today shows its waiting ring until this moment lights it.
    private func dayShown(_ i: Int) -> DailyReport.Day {
        let d = report.week[i]
        if lights && d == .todayLit && !todayLit { return .today }
        return d
    }

    /// The day's "why" (after a missed day, the one about never missing twice).
    private var quote: String {
        switch report.story {
        case .comeback, .repair: return "Your progress is all still here."
        default: return report.quote
        }
    }

    private var storyLine: String {
        if let f = evolvedTo, revealed { return "\(f.days) days in a row. This form is yours for good." }
        if evolvedTo != nil && todayLit { return "\(report.streak) days in a row." }
        if let m = milestone, todayLit {
            return m >= 66 ? "\(m) days in a row. This is who you are now." : "\(m) days in a row. Your flame burns steadier every day."
        }
        return lights && !todayLit ? before.line : report.line
    }

    @ViewBuilder private var growthCard: some View {
        // Yesterday's numbers until today lights (and, for a new form, until it's revealed).
        let r = (lights && !todayLit) || (evolvedTo != nil && !revealed) ? before : report
        VStack(spacing: 0) {
            GrowthRow(bar: r.form, fill: fills[0], goal: revealed ? report.nextForm : r.nextForm, detailGold: true) {
                Image(uiImage: UIImage(named: (revealed ? (evolvedTo ?? shownForm) : shownForm).base + "-keyed.png") ?? UIImage())
                    .resizable().scaledToFit()
            }
            .opacity(barsShown >= 1 ? 1 : 0)
            if !isLit {
                hairline
                GrowthRow(bar: report.level, fill: fills[1]) { LevelBadge(level: report.level.level, pop: 0, size: 40) }
                    .opacity(barsShown >= 2 ? 1 : 0)
                hairline
                GrowthRow(bar: report.skill, fill: fills[2]) {
                    Image(uiImage: UIImage(named: "pillar-\((report.skill.pillar ?? .body).rawValue.lowercased()).png") ?? UIImage())
                        .resizable().scaledToFit()
                }
                .opacity(barsShown >= 3 ? 1 : 0)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
        .background(card(22))
    }

    @ViewBuilder private var bottom: some View {
        if isLit && !(revealed) {
            Text("Tap to continue").font(.ui(13, .semibold)).foregroundStyle(Theme.cream.opacity(0.45)).padding(.bottom, 22)
                .opacity(todayLit ? 1 : 0)
        } else {
            Button { leave() } label: {
                HStack(spacing: 10) {
                    Text(isLit ? "Keep going" : "Let's go").font(.story(23, .semibold))
                    if !isLit && report.pouch > 0 {
                        EmberCoin(size: 30)
                        Text("+\(report.pouch)").font(.num(22, .heavy))
                    }
                }
                .foregroundStyle(Color(red: 0.27, green: 0.15, blue: 0.06))
                .frame(maxWidth: .infinity).frame(height: 58)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 1, green: 0.94, blue: 0.78), Theme.champagne], startPoint: .top, endPoint: .bottom)))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.champagneDeep, lineWidth: 1))
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.warmShadow.opacity(0.55)).offset(y: 5))
            }
            .buttonStyle(PressableStyle())
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { buttonFrame = $0 }
            .padding(.bottom, 10)
            .opacity(tailIn ? 1 : 0).offset(y: tailIn ? 0 : 16)
            .allowsHitTesting(tailIn)
        }
    }

    private var hairline: some View { Rectangle().fill(Theme.cream.opacity(0.12)).frame(height: 0.5) }

    private func card(_ corner: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Color(red: 0.17, green: 0.115, blue: 0.09))
            .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(Theme.champagne.opacity(0.22), lineWidth: 1))
            .background(RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Color.black.opacity(0.35)).offset(y: 4))   // a crisp lip
    }

    // MARK: The moment

    private func start() {
        guard run == nil else { return }
        run = Task { @MainActor in await play() }
    }

    /// The moment: the Flame and the number rise in; the week appears; today lights (the number ticks up, its box
    /// catches fire); a new form is revealed if one was reached; then (the morning) the bars slide right from where you
    /// were 7 days ago, the day's "why" and "Let's go". The short lit version closes by itself (or waits on a new form).
    private func play() async {
        let r = report
        await stage.waitReady()
        await stage.waitDrawn()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { appeared = true }
        guard await wait(isLit ? 200 : 350) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) { numberIn = true }
        if isLit {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { weekShown = 7; barsShown = 1 }
        } else {
            guard await wait(320) else { return }
            for i in 0..<7 {
                if [.lived, .repaired, .shielded].contains(r.week[i]) { XPHaptics.selection.selectionChanged() }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.68)) { weekShown = i + 1 }
                guard await wait(70) else { return }
            }
        }
        if lights {                                             // today lights
            guard await wait(isLit ? 450 : 300) else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            stage.cheer()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { shownStreak = r.streak; todayLit = true; litPop += 1 }
            guard await wait(450) else { return }
        }
        if let f = evolvedTo {                                  // a new form
            if isLit { XPHaptics.fill(ticks: 4, over: 0.6); withAnimation(.easeOut(duration: 0.7)) { fills[0] = 1 } }
            guard await wait(isLit ? 900 : 500) else { return }
            withAnimation(.easeIn(duration: 0.18)) { flash = 0.85 }
            guard await wait(180) else { return }
            await stage.become(f)
            XPHaptics.levelUp()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { revealed = true; litPop += 1; if isLit { fills[0] = r.form.now } }
            withAnimation(.easeOut(duration: 0.7)) { flash = 0 }
            if isLit {                                          // the new form waits for "Keep going"
                withAnimation(.easeOut(duration: 0.4)) { tailIn = true }
                finished = true
                return
            }
            guard await wait(900) else { return }
        }
        if isLit {
            XPHaptics.fill(ticks: 4, over: 0.6)
            withAnimation(.easeOut(duration: 0.7)) { fills[0] = r.form.now }
            finished = true
            guard await wait(milestone != nil ? 3200 : 2200) else { return }
            leave()
            return
        }
        guard await wait(220) else { return }
        let targets = [r.form.now, r.level.now, r.skill.now]
        for k in 0..<3 {
            withAnimation(.easeOut(duration: 0.25)) { barsShown = k + 1 }
            guard await wait(140) else { return }
            if targets[k] > fills[k] + 0.01 { XPHaptics.fill(ticks: 5, over: 0.7) }
            withAnimation(.easeOut(duration: 0.8)) { fills[k] = targets[k] }
            guard await wait(380) else { return }
        }
        guard await wait(250) else { return }
        withAnimation(.easeOut(duration: 0.4)) { tailIn = true }
        finished = true
    }

    /// Waits, unless the moment was skipped.
    private func wait(_ ms: Int) async -> Bool {
        try? await Task.sleep(for: .milliseconds(ms))
        return !Task.isCancelled
    }

    /// A tap skips the moment to its end (or, lit, closes it).
    private func tapped() {
        if isLit {
            if revealed { return }                              // a new form waits for "Keep going"
            if finished { leave() }
            return
        }
        guard !finished else { return }
        run?.cancel()
        let r = report
        if let f = evolvedTo, !revealed { Task { @MainActor in await stage.become(f) } }
        withAnimation(.easeOut(duration: 0.3)) {
            appeared = true; numberIn = true; weekShown = 7; barsShown = 3
            shownStreak = r.streak; todayLit = lights; revealed = evolvedTo != nil
            fills = [r.form.now, r.level.now, r.skill.now]; tailIn = true
        }
        finished = true
    }

    private func leave() {
        run?.cancel()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        close(isLit || report.pouch == 0 ? nil : CGPoint(x: buttonFrame.midX, y: buttonFrame.midY))
    }
}
