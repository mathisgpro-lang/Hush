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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(uiImage: SparkTint.image("spark-keyed.png", ember: ember) ?? UIImage()).resizable().scaledToFit().frame(width: 34, height: 44)
                    .shadow(color: .orange.opacity(0.8), radius: 8)
                Text(text).font(.system(size: 16, design: .serif)).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button("Skip the tour", action: skip).font(.system(size: 13, design: .serif)).foregroundStyle(.white.opacity(0.6))
                Spacer()
                Button(action: next) {
                    Text(button).font(.system(size: 15, weight: .semibold, design: .serif))
                        .padding(.horizontal, 18).padding(.vertical, 9)
                        .background(Capsule().fill(LinearGradient(colors: [gold, Color(red: 0.93, green: 0.55, blue: 0.25)], startPoint: .top, endPoint: .bottom)))
                        .foregroundStyle(Color(red: 0.25, green: 0.12, blue: 0.05))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color(red: 0.12, green: 0.08, blue: 0.1).opacity(0.92)))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(gold.opacity(0.5), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }
}
