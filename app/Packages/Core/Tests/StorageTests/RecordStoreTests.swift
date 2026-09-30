import Foundation
import Testing
import GRDB
@testable import Storage
import Domain

struct RecordStoreTests {
    private func sample(_ key: String = "walk") -> Entry {
        let tz = TimeZone(identifier: "Europe/Paris")!
        return Entry.make(.actionCompleted(occurrenceKey: key, pillarWeights: [.body: 1], d: 1, isSpark: false),
                          at: Date(timeIntervalSince1970: 1_790_000_000),
                          settings: EngineSettings(timeZone: tz))
    }

    @Test func whatIsWrittenIsReadBackExactly() throws {
        let store = try RecordStore.inMemory()
        let e = sample()
        try store.append(e)
        #expect(try store.allEntries() == [e])
    }

    @Test func theRecordRefusesEdits() throws {
        let store = try RecordStore.inMemory()
        try store.append(sample())
        #expect(throws: (any Error).self) {
            try store.dbQueue.write { try $0.execute(sql: "UPDATE entries SET kind = 'x'") }
        }
    }

    @Test func theRecordRefusesDeletingSingleEntries() throws {
        let store = try RecordStore.inMemory()
        try store.append(sample())
        #expect(throws: (any Error).self) {
            try store.dbQueue.write { try $0.execute(sql: "DELETE FROM entries") }
        }
        #expect(try store.allEntries().count == 1)
    }

    @Test func appendingTheSameEntryTwiceIsHarmless() throws {
        let store = try RecordStore.inMemory()
        let e = sample()
        try store.append(e)
        try store.append(e)
        #expect(try store.allEntries().count == 1)
    }

    @Test func aDifferentEntryWithAnExistingIdIsRejected() throws {
        let store = try RecordStore.inMemory()
        let e = sample("walk")
        try store.append(e)
        let impostor = Entry(id: e.id, occurredAt: e.occurredAt, recordedAt: e.recordedAt, timeZone: e.timeZone,
                             livedDay: e.livedDay, payload: .momentWitnessed(key: "x"))
        #expect(throws: RecordStore.StoreError.conflictingDuplicate) { try store.append(impostor) }
    }

    @Test func deleteEverythingEmptiesTheRecord() throws {
        let store = try RecordStore.inMemory()
        try store.append(sample())
        try store.deleteEverything()
        #expect(try store.allEntries().isEmpty)
    }

    @Test func theRecordSurvivesReopeningTheFile() throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite").path
        let e = sample()
        do { try RecordStore(path: path).append(e) }
        #expect(try RecordStore(path: path).allEntries() == [e])
    }
}
