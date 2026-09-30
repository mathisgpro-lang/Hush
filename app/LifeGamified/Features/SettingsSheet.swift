import SwiftUI
import UniformTypeIdentifiers
import Domain

/// Settings (chapter 05 §B.4, chapter 17 §B.8–B.9): your morning time, a backup you own, and deleting everything.
struct SettingsSheet: View {
    let model: AppModel
    @State private var notifyOn = DaylightNotifier.scheduledMinutes != nil
    @State private var time = Calendar.current.date(from: DateComponents(
        hour: (DaylightNotifier.scheduledMinutes ?? 450) / 60, minute: (DaylightNotifier.scheduledMinutes ?? 450) % 60)) ?? .now
    @State private var exportDoc: RecordDocument?
    @State private var confirmDelete = false
    @State private var deleteTyped = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Tell me when my day is ready", isOn: $notifyOn)
                    if notifyOn { DatePicker("At", selection: $time, displayedComponents: .hourAndMinute) }
                } header: { Text("Morning") } footer: {
                    Text("At most one gentle notification a day. Never about streaks or missed days.")
                }
                Section {
                    Button("Save a backup of my record") { exportDoc = RecordDocument(data: model.exportRecord()) }
                } header: { Text("Your record") } footer: {
                    Text("Everything you've done lives on this phone. A backup is a file you keep wherever you like (Files, iCloud Drive…). \(model.entries.count) entries.")
                }
                Section {
                    Button("Delete everything", role: .destructive) { confirmDelete = true }
                } footer: {
                    Text("Removes your Flame and your whole record from this phone. Backups you saved are yours and aren't touched.")
                }
            }
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .onChange(of: notifyOn) { _, on in update(on) }
            .onChange(of: time) { _, _ in if notifyOn { update(true) } }
            .fileExporter(isPresented: Binding(get: { exportDoc != nil }, set: { if !$0 { exportDoc = nil } }),
                          document: exportDoc, contentType: .json,
                          defaultFilename: "life-gamified-record-\(model.state.today)") { _ in exportDoc = nil }
            .alert("Delete everything?", isPresented: $confirmDelete) {
                TextField("Type DELETE", text: $deleteTyped)
                Button("Delete", role: .destructive) { if deleteTyped == "DELETE" { model.deleteEverythingForReal() } ; deleteTyped = "" }
                Button("Cancel", role: .cancel) { deleteTyped = "" }
            } message: { Text("This can't be undone. Type DELETE to confirm.") }
        }
        .preferredColorScheme(.dark)
    }

    private func update(_ on: Bool) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: time)
        if on {
            Task { let ok = await DaylightNotifier.requestAndSchedule(hour: c.hour ?? 7, minute: c.minute ?? 30); if !ok { notifyOn = false } }
        } else { DaylightNotifier.cancel() }
    }
}

struct RecordDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
