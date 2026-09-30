import Foundation

/// A slot in a day contract (chapter 04 §B.1 `dayPlanned`). P-class: structure and numbers only.
public struct PlannedSlot: Codable, Sendable, Equatable, Hashable {
    public let occurrenceKey: String
    public let pillarWeights: [Pillar: Double]
    public let d: Double
    public let isSpark: Bool

    public init(occurrenceKey: String, pillarWeights: [Pillar: Double], d: Double, isSpark: Bool) {
        self.occurrenceKey = occurrenceKey
        self.pillarWeights = pillarWeights
        self.d = d
        self.isSpark = isSpark
    }
}

/// Entry payloads used by Slice 1 (a subset of chapter 17 §B.3; more kinds arrive with later slices).
public enum Payload: Codable, Sendable, Equatable {
    case flameBorn(seed: String)
    case pathStarted(pathId: String, templateId: String, pillar: Pillar)
    case dayPlanned(isPlannedRest: Bool, slots: [PlannedSlot])
    case actionCompleted(occurrenceKey: String, pillarWeights: [Pillar: Double], d: Double, isSpark: Bool)
    case correctionVoid(targetId: UUID)
    case momentWitnessed(key: String)

    public var kind: String {
        switch self {
        case .flameBorn: "flameBorn"
        case .pathStarted: "pathStarted"
        case .dayPlanned: "dayPlanned"
        case .actionCompleted: "actionCompleted"
        case .correctionVoid: "correction"
        case .momentWitnessed: "momentWitnessed"
        }
    }
}

/// One immutable record entry: the P envelope (chapter 17 §B.2).
public struct Entry: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let occurredAt: Date
    public let recordedAt: Date
    public let timeZone: String
    public let livedDay: LocalDate
    public let payload: Payload

    public init(id: UUID = UUID(), occurredAt: Date, recordedAt: Date, timeZone: String,
                livedDay: LocalDate, payload: Payload) {
        self.id = id
        self.occurredAt = occurredAt
        self.recordedAt = recordedAt
        self.timeZone = timeZone
        self.livedDay = livedDay
        self.payload = payload
    }

    /// Creates an entry for something happening now (or at `occurredAt`) in the user's current zone.
    public static func make(_ payload: Payload, at occurredAt: Date = .now, settings: EngineSettings) -> Entry {
        Entry(occurredAt: occurredAt, recordedAt: .now, timeZone: settings.timeZone.identifier,
              livedDay: LivedDayRule.livedDay(at: occurredAt, in: settings.timeZone, boundary: settings.boundary),
              payload: payload)
    }
}
