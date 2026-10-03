// SpikeLab: throwaway P2 test app (docs/plan-2.0/p2-phase-plan.md). Never merged into app/, never touches the real record.
import SwiftUI

@main
struct SpikeLabApp: App {
    init() { _ = AppTimer.start }           // launch timing starts here
    var body: some Scene {
        WindowGroup {
            if !CommandLine.arguments.contains("-lab") { AppShellView() } else {
            NavigationStack {
                if CommandLine.arguments.contains("-probe") { ProbeView() }
                else if CommandLine.arguments.contains("-s1") { S1Screen() }
                else if CommandLine.arguments.contains("-s2") { S2View() }
                else if CommandLine.arguments.contains("-s3") { S3View() }
                else { menu }
            }
            .preferredColorScheme(.dark)
            }
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
                        NavigationLink("S3 · Restoration (the Grove)") { S3View() }
                    }
                }
                .navigationTitle("SpikeLab")
    }
}
