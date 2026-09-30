import Foundation
import GRDB
import Domain

/// The permanent, append-only record on the phone (chapter 17 §B.1–B.2). Entries are never edited or
/// deleted one by one; mistakes are fixed with correction entries. Only "delete everything" empties it.
public final class RecordStore: Sendable {
    public enum StoreError: Error, Equatable { case conflictingDuplicate }

    let dbQueue: DatabaseQueue
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    public init(path: String) throws {
        dbQueue = try DatabaseQueue(path: path)
        try Self.migrator.migrate(dbQueue)
    }

    init(queue: DatabaseQueue) throws {
        dbQueue = queue
        try Self.migrator.migrate(dbQueue)
    }

    public static func inMemory() throws -> RecordStore { try RecordStore(queue: DatabaseQueue()) }

    /// The default on-device location (Application Support/record.sqlite).
    public static func onDevice() throws -> RecordStore {
        let dir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                              appropriateFor: nil, create: true)
        return try RecordStore(path: dir.appendingPathComponent("record.sqlite").path)
    }

    private static var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1-entries") { db in
            try db.execute(sql: """
                CREATE TABLE entries (
                    id TEXT PRIMARY KEY NOT NULL,
                    kind TEXT NOT NULL,
                    livedDay TEXT NOT NULL,
                    occurredAt DOUBLE NOT NULL,
                    json BLOB NOT NULL
                );
                CREATE INDEX entries_livedDay ON entries(livedDay);
                CREATE TABLE maintenance (deleting INTEGER NOT NULL);
                INSERT INTO maintenance (deleting) VALUES (0);
                CREATE TRIGGER entries_no_update BEFORE UPDATE ON entries
                BEGIN SELECT RAISE(ABORT, 'the record is append-only'); END;
                CREATE TRIGGER entries_no_delete BEFORE DELETE ON entries
                WHEN (SELECT deleting FROM maintenance) = 0
                BEGIN SELECT RAISE(ABORT, 'the record is append-only'); END;
                """)
        }
        return m
    }

    public func append(_ entry: Entry) throws {
        let json = try Self.encoder.encode(entry)
        try dbQueue.write { db in
            if let existing = try Foundation.Data.fetchOne(db, sql: "SELECT json FROM entries WHERE id = ?",
                                                arguments: [entry.id.uuidString]) {
                guard existing == json else { throw StoreError.conflictingDuplicate }
                return
            }
            try db.execute(sql: "INSERT INTO entries (id, kind, livedDay, occurredAt, json) VALUES (?, ?, ?, ?, ?)",
                           arguments: [entry.id.uuidString, entry.payload.kind, entry.livedDay.description,
                                       entry.occurredAt.timeIntervalSince1970, json])
        }
    }

    public func allEntries() throws -> [Entry] {
        let rows = try dbQueue.read { db in
            try Foundation.Data.fetchAll(db, sql: "SELECT json FROM entries ORDER BY livedDay, occurredAt, id")
        }
        let decoder = JSONDecoder()
        return try rows.map { try decoder.decode(Entry.self, from: $0) }
    }

    /// "Delete everything" (chapter 16 §B.9, local part). Sync-side deletion arrives with the sync slice.
    public func deleteEverything() throws {
        try dbQueue.write { db in
            try db.execute(sql: "UPDATE maintenance SET deleting = 1")
            try db.execute(sql: "DELETE FROM entries")
            try db.execute(sql: "UPDATE maintenance SET deleting = 0")
        }
    }
}
