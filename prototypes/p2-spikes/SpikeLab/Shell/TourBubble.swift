// The guided tour right after the introduction (iteration 2): your Spark shows you around in one or two lines per
// stop (the Sanctuary's satchel and world, the map, the Grove), always with a clear next step and a way to skip.
import SwiftUI

struct TourBubble: View {
    let text: String
    var ember: String = UserDefaults.standard.string(forKey: "ember.id") ?? "craft"
    let button: String
    var pointsDown = true
    let next: () -> Void
    let skip: () -> Void
    private let gold = Color(red: 1, green: 0.78, blue: 0.42)
    var body: some View {
        // A parchment scroll in the Spark's voice, as in the introduction (one look for every dialogue).
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(uiImage: SparkTint.image(PixelMode.sparkImage, ember: ember) ?? UIImage()).resizable().scaledToFit().frame(width: 34, height: 44)
                    .shadow(color: .orange.opacity(0.6), radius: 6)
                Text(text).font(.story(17)).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button("Skip the tour", action: skip).font(.ui(13, .semibold)).foregroundStyle(Theme.ink.opacity(0.55))
                Spacer()
                Button(action: next) { GoldButtonLabel(text: button).frame(width: 150) }.buttonStyle(PressableStyle())
            }
        }
        .padding(18)
        .background(SheetPaper(corner: 22))
        .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }
}
