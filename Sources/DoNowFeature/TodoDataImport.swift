import Foundation
import SwiftData

/// DoNow 앱의 "MyDays로 내보내기"가 만드는 JSON과 같은 포맷.
private struct TodoItemExport: Codable {
    let id: UUID
    let title: String
    let type: TodoType
    let repeatDays: [Int]?
    let frequency: RepeatFrequency?
    let dueDate: Date?
    let isUrgent: Bool
    let createdAt: Date
    let isArchived: Bool
    let memo: String?
}

private struct CompletionRecordExport: Codable {
    let todoId: UUID
    let date: String
    let completedAt: Date
}

private struct TodoDataExportBundle: Codable {
    let items: [TodoItemExport]
    let completions: [CompletionRecordExport]
}

public enum TodoDataImport {
    public static func importFile(at url: URL, into context: ModelContext) throws {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let bundle = try decoder.decode(TodoDataExportBundle.self, from: data)

        for entry in bundle.items {
            let item = TodoItem(
                title: entry.title, type: entry.type, repeatDays: entry.repeatDays,
                frequency: entry.frequency, dueDate: entry.dueDate, isUrgent: entry.isUrgent
            )
            item.id = entry.id
            item.createdAt = entry.createdAt
            item.isArchived = entry.isArchived
            item.memo = entry.memo
            context.insert(item)
        }
        for entry in bundle.completions {
            context.insert(CompletionRecord(todoId: entry.todoId, date: entry.date))
        }
    }
}
