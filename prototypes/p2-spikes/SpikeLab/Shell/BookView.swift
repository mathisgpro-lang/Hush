// The Book of Your Flame (decision 129): it writes itself as you live. It opens on the world you're in; each world
// you've been to is a chapter; each page was written on the day something really happened, in the story's voice and
// with your own words. The last page is always blank: the next one is yours to write.
import SwiftUI

struct BookView: View {
    let model: ShellModel
    @Binding var isOpen: Bool
    let openOn: String                                   // the world you're in (RealmID raw value or "emberlands")
    @State private var chapter = ""
    @State private var page = 0
    private let ink = Color(red: 0.27, green: 0.17, blue: 0.1)
    private let gold = Color(red: 0.75, green: 0.58, blue: 0.3)

    private static let order = ["sanctuary", "emberlands", "grove", "stillwater", "highlands", "library", "wilds", "forge", "veil"]
    private func worldName(_ w: String) -> String { w == "emberlands" ? "The Emberlands" : (RealmID(rawValue: w)?.name ?? w) }
    private func vignette(_ w: String) -> String {
        if w == "emberlands" { return "world-map.png" }
        if w == "sanctuary" { return "home-paint.png" }
        return UIImage(named: "\(w)-world-paint.png") != nil ? "\(w)-world-paint.png" : "home-paint.png"     // each realm's own painting
    }
    /// The vignettes, shrunk once to page size (resizing a big painting on every frame slowed the page turns).
    private static var thumbs: [String: UIImage] = [:]
    static func thumb(_ name: String) -> UIImage {
        if let t = thumbs[name] { return t }
        guard let src = UIImage(named: name) else { return UIImage() }
        let w: CGFloat = 700, h = w * src.size.height / src.size.width
        let t = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { _ in src.draw(in: CGRect(x: 0, y: 0, width: w, height: h)) }
        thumbs[name] = t
        return t
    }
    private var chapters: [String] { Self.order.filter { w in model.journey.pages.contains { $0.world == w } } }
    private var pages: [BookPage] { model.journey.pages.filter { $0.world == chapter }.sorted { $0.date < $1.date } }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { close() }
            VStack(spacing: 0) {
                Capsule().fill(ink.opacity(0.3)).frame(width: 40, height: 5).padding(.top, 10)
                HStack(alignment: .firstTextBaseline) {
                    Text(model.journey.name.isEmpty ? "The Book of Your Flame" : "The Book of \(model.journey.name)'s Flame")
                        .font(.story(22)).foregroundStyle(ink)
                    Spacer()
                    Button { close() } label: {
                        Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(ink.opacity(0.6))
                            .frame(width: 30, height: 30).background(Circle().fill(ink.opacity(0.08)))
                    }
                }
                .padding(.horizontal, 22).padding(.top, 8)
                chapterTabs.padding(.top, 8)
                if chapters.isEmpty {
                    blankPage(first: true).frame(height: 440)
                } else {
                    TabView(selection: $page) {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { i, p in pageView(p).tag(i) }
                        blankPage(first: false).tag(pages.count)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 440)
                    .id(chapter)
                    pageDots.padding(.bottom, 14)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(colors: [Color(red: 0.98, green: 0.93, blue: 0.82), Color(red: 0.93, green: 0.85, blue: 0.7)], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(gold.opacity(0.7), lineWidth: 1.5))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(gold.opacity(0.3), lineWidth: 1).padding(6))
                    .shadow(color: .black.opacity(0.45), radius: 20, y: 6)
            )
            .padding(.horizontal, 10).padding(.bottom, 8)
        }
        .onAppear {
            chapter = chapters.contains(openOn) ? openOn : (chapters.first ?? "")
            page = max(0, pages.count - 1)                 // open on the latest page written
            model.journey.bookOpened()
        }
    }

    private var chapterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chapters, id: \.self) { w in
                    Button {
                        withAnimation(.spring(duration: 0.35)) { chapter = w; page = max(0, pages.count - 1) }
                    } label: {
                        Text(worldName(w)).font(.ui(13, .bold))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(chapter == w ? Color(red: 0.45, green: 0.32, blue: 0.15) : .clear))
                            .overlay(Capsule().stroke(Color(red: 0.45, green: 0.32, blue: 0.15).opacity(0.6), lineWidth: 1))
                            .foregroundStyle(chapter == w ? Color(red: 1, green: 0.93, blue: 0.8) : ink)
                    }
                }
            }
            .padding(.horizontal, 22)
        }
    }

    private func pageView(_ p: BookPage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(uiImage: Self.thumb(vignette(p.world))).resizable().scaledToFill()
                .frame(height: 130).frame(maxWidth: .infinity).clipped()
                .saturation(0.8).overlay(LinearGradient(colors: [.clear, Color(red: 0.96, green: 0.9, blue: 0.78).opacity(0.85)], startPoint: .center, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(gold.opacity(0.5), lineWidth: 1))
            Text("Day \(model.journey.dayNumber(of: p.date)) · \(p.date.formatted(.dateTime.day().month(.wide)))")
                .font(.ui(12, .semibold)).foregroundStyle(ink.opacity(0.55))
            Text(p.title).font(.story(26, .semibold)).foregroundStyle(ink)
            Text(p.text).font(.story(17)).foregroundStyle(ink.opacity(0.85)).lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22).padding(.top, 10)
    }

    private func blankPage(first: Bool) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "pencil.and.scribble").font(.system(size: 30)).foregroundStyle(gold)
            Text(first ? "The pages are still empty." : "The next page is yours to write.")
                .font(.story(20)).foregroundStyle(ink)
            Text(first ? "Every real thing you do will write a line here." : "Live something today, and your Spark will write it down.")
                .font(.ui(15)).foregroundStyle(ink.opacity(0.65)).multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 30)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0...pages.count, id: \.self) { i in
                Circle().fill(i == page ? Color(red: 0.45, green: 0.32, blue: 0.15) : ink.opacity(0.2)).frame(width: 6, height: 6)
            }
        }
    }

    private func close() { withAnimation(.sheet) { isOpen = false } }
}
