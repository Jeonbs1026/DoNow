import Foundation
import SwiftData

@Model
public final class CompletionRecord {
    public var id: UUID
    public var todoId: UUID
    public var date: String
    var completedAt: Date

    init(todoId: UUID, date: String) {
        self.id = UUID()
        self.todoId = todoId
        self.date = date
        self.completedAt = Date()
    }
}
