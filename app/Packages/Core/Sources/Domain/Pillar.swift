/// The six universal pillars (chapter 04 §A.2). Order is normative (tie-breaks use it).
public enum Pillar: Int, CaseIterable, Sendable, Hashable, Codable, CodingKeyRepresentable {
    case body, mind, heart, spirit, craft, world
}
