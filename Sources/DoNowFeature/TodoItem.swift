import Foundation
import SwiftData

enum TodoType: String, Codable {
    case habit
    case task
}

/// habit에만 적용. 옛 레코드엔 컬럼 자체가 없으니 옵셔널로 두고
/// `effectiveFrequency`에서 nil을 daily로 취급해 마이그레이션 없이 호환한다.
enum RepeatFrequency: String, Codable {
    case daily
    case weekly
    case monthly
}

@Model
public final class TodoItem {
    public var id: UUID
    public var title: String
    var type: TodoType
    var repeatDays: [Int]?
    var frequency: RepeatFrequency?
    var dueDate: Date?
    var isUrgent: Bool
    var createdAt: Date
    var isArchived: Bool
    var memo: String?
    /// 목록에서 사용자가 직접 정한 순서. 값이 같으면 생성일순으로 정렬.
    var sortOrder: Int = 0

    var effectiveFrequency: RepeatFrequency { frequency ?? .daily }

    init(
        title: String,
        type: TodoType,
        repeatDays: [Int]? = nil,
        frequency: RepeatFrequency? = nil,
        dueDate: Date? = nil,
        isUrgent: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.repeatDays = repeatDays
        self.frequency = frequency
        self.dueDate = dueDate
        self.isUrgent = isUrgent
        self.createdAt = Date()
        self.isArchived = false
        self.memo = nil
    }
}
