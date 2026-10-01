// SpikeLab: throwaway P2 test app (docs/plan-2.0/p2-phase-plan.md). Never merged into app/, never touches the real record.
import SwiftUI

@main
struct SpikeLabApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if CommandLine.arguments.contains("-probe") { ProbeView() }
                else if CommandLine.arguments.contains("-s1") { S1Screen() }
                else if CommandLine.arguments.contains("-s2") { S2View() }
                else { menu }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var menu: some View {
                List {
                    Section("Step 0") {
                        NavigationLink("Pipeline probe") { ProbeView() }
                    }
                    Section("Spikes") {
                        NavigationLink("S1 · The living Flame") { S1Screen() }
                        NavigationLink("S2 · The Sanctuary (painted)") { S2View() }
                        Text("S3 · Restoration").foregroundStyle(.secondary)
                    }
                }
                .navigationTitle("SpikeLab")
    }
}
