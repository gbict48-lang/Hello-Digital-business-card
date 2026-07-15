import Foundation
import Observation

/// Owns all business cards and persists them as JSON in Application Support.
/// Uses the Observation framework (`@Observable`) so SwiftUI views update
/// automatically when cards change.
@Observable
final class CardStore {
    private(set) var cards: [BusinessCard] = []

    /// The id of the card the user has chosen as their primary/default card.
    var primaryCardID: UUID?

    @ObservationIgnored
    private let fileURL: URL

    @ObservationIgnored
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    @ObservationIgnored
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private struct Persisted: Codable {
        var cards: [BusinessCard]
        var primaryCardID: UUID?
    }

    init(fileName: String = "cards.json") {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent(fileName)
        load()
    }

    var primaryCard: BusinessCard? {
        guard let id = primaryCardID else { return cards.first }
        return cards.first { $0.id == id } ?? cards.first
    }

    // MARK: - Mutations

    func add(_ card: BusinessCard) {
        cards.insert(card, at: 0)
        if primaryCardID == nil { primaryCardID = card.id }
        save()
    }

    func update(_ card: BusinessCard) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else {
            add(card)
            return
        }
        var updated = card
        updated.updatedAt = Date()
        cards[index] = updated
        save()
    }

    func delete(_ card: BusinessCard) {
        cards.removeAll { $0.id == card.id }
        if primaryCardID == card.id { primaryCardID = cards.first?.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        let removed = offsets.map { cards[$0] }
        cards.remove(atOffsets: offsets)
        if let primary = primaryCardID, removed.contains(where: { $0.id == primary }) {
            primaryCardID = cards.first?.id
        }
        save()
    }

    func makePrimary(_ card: BusinessCard) {
        primaryCardID = card.id
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let payload = try? decoder.decode(Persisted.self, from: data) {
            cards = payload.cards
            primaryCardID = payload.primaryCardID
        }
    }

    private func save() {
        let payload = Persisted(cards: cards, primaryCardID: primaryCardID)
        guard let data = try? encoder.encode(payload) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}
