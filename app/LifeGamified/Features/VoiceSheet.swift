import SwiftUI
import Domain

/// The Voice (First Journey step IV, chapter 07): your Companion's guidance for each of your Paths, always with
/// its sources. v1 is curated knowledge, not generative AI (decision 73: no on-device model on this iPhone).
struct VoiceSheet: View {
    let model: AppModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("I'm your Companion. For each of your Paths, here's why it matters and how to make it stick, with where it comes from.")
                        .font(Theme.ceremonial(16)).foregroundStyle(.secondary)
                }
                ForEach(model.activePaths, id: \.pathId) { path in
                    if let t = Catalog.path(path.templateId), let k = Knowledge.byPath[path.templateId] {
                        Section {
                            Text(k.why).font(.body)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Making it stick").font(.caption).foregroundStyle(.secondary)
                                ForEach(k.howToStick, id: \.self) { tip in
                                    Label(tip, systemImage: "flame").font(.subheadline)
                                }
                            }
                            .padding(.vertical, 4)
                            ForEach(k.sourceIds, id: \.self) { id in
                                if let s = Knowledge.source(id) {
                                    Button { openURL(s.url) } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Based on: \(s.title)").font(.caption)
                                            Text("\(s.publisher) · \(s.year)").font(.caption2).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text("\(t.pillar.name) · \(t.name)")
                        }
                    }
                }
                Section {
                    Text("General guidance, not medical advice. For health concerns, talk to a professional.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("The Voice").navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}
