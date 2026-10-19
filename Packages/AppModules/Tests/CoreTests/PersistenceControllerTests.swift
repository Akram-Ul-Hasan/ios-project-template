import CoreData
import Foundation
import Testing

@testable import Core

@Suite("PersistenceController")
struct PersistenceControllerTests {
    /// A one-entity model built in code: Note(id: String).
    private static func model() -> NSManagedObjectModel {
        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .stringAttributeType
        let note = NSEntityDescription()
        note.name = "Note"
        note.properties = [id]
        let model = NSManagedObjectModel()
        model.entities = [note]
        return model
    }

    private func insertNotes(_ ids: [String], into persistence: PersistenceController) async throws {
        let context = persistence.container.newBackgroundContext()
        try await context.perform {
            for id in ids {
                NSEntityDescription.insertNewObject(forEntityName: "Note", into: context).setValue(id, forKey: "id")
            }
            try context.save()
        }
    }

    private func count(in persistence: PersistenceController) async throws -> Int {
        let context = persistence.container.newBackgroundContext()
        return try await context.perform { try context.count(for: NSFetchRequest(entityName: "Note")) }
    }

    @Test("Saves and fetches on background contexts")
    func saveAndFetch() async throws {
        let persistence = PersistenceController(name: "Test", models: [Self.model()], location: .inMemory)
        try await persistence.load()
        try await insertNotes(["a", "b"], into: persistence)
        #expect(try await count(in: persistence) == 2)
    }

    @Test("clearSessionData deletes every row")
    func clear() async throws {
        let persistence = PersistenceController(name: "Test", models: [Self.model()], location: .inMemory)
        try await persistence.load()
        try await insertNotes(["a", "b", "c"], into: persistence)
        try await persistence.clearSessionData()
        #expect(try await count(in: persistence) == 0)
    }
}
