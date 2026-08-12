import Foundation
import SwiftData
import WidgetKit

public enum TodayFilter {
    public static let widgetKind = "TodayWidget"

    public static func toggleCompletion(todoId: UUID, dateKey: String, in context: ModelContext) {
        let descriptor = FetchDescriptor<CompletionRecord>(
            predicate: #Predicate { $0.todoId == todoId && $0.date == dateKey }
        )
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        } else {
            context.insert(CompletionRecord(todoId: todoId, date: dateKey))
        }
        commitChange(in: context)
    }

    /// 위젯은 별도 프로세스에서 앱 그룹 파일을 새로 읽으므로, 로컬 변경 후 저장과
    /// 리로드 신호를 함께 보내야 위젯에 반영된다.
    static func commitChange(in context: ModelContext) {
        try? context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    /// TodoItem을 지울 때 그 항목의 완료 기록도 함께 지운다 — 그러지 않으면
    /// todoId가 가리키는 항목이 없는 CompletionRecord가 영구히 쌓여 조회 비용만 늘어난다.
    static func deleteTodoItem(_ item: TodoItem, in context: ModelContext) {
        let todoId = item.id
        let descriptor = FetchDescriptor<CompletionRecord>(predicate: #Predicate { $0.todoId == todoId })
        if let orphaned = try? context.fetch(descriptor) {
            for record in orphaned { context.delete(record) }
        }
        context.delete(item)
        commitChange(in: context)
    }

    /// 하루의 경계는 자정이 아니라 새벽 4시 — 그 전(0~3시대)은 아직 "어제"로 취급한다.
    /// 늦게 자는 사용자가 자정을 넘겨 활동해도 습관 노출/완료 판정이 도중에 안 끊기도록.
    static let dayStartHour = 4

    /// now가 가리키는 "앱 기준 하루"의 대표 시각. dayStartHour 이전이면 전날로 보정.
    static func appDay(_ now: Date, calendar: Calendar = .current) -> Date {
        let hour = calendar.component(.hour, from: now)
        guard hour < dayStartHour else { return now }
        return calendar.date(byAdding: .day, value: -1, to: now) ?? now
    }

    public static func todayWeekday(now: Date = Date(), calendar: Calendar = .current) -> Int {
        calendar.component(.weekday, from: appDay(now, calendar: calendar)) - 1
    }

    /// DateFormatter는 스레드 세이프하지 않다 — 앱(메인 스레드)과 위젯 익스텐션이
    /// 동시에 호출할 수 있으므로, 공유 인스턴스를 재사용하는 대신 순수 계산으로 처리한다.
    static func dateKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: appDay(date, calendar: calendar))
        guard let year = components.year, let month = components.month, let day = components.day else {
            return ""
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func weekKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: appDay(date, calendar: calendar))
        guard let year = components.yearForWeekOfYear, let week = components.weekOfYear else { return "" }
        return String(format: "%04d-W%02d", year, week)
    }

    static func monthKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month], from: appDay(date, calendar: calendar))
        guard let year = components.year, let month = components.month else { return "" }
        return String(format: "%04d-%02d", year, month)
    }

    /// 완료 기록을 어느 기간 단위로 묶을지 — task/daily habit은 하루, weekly/monthly habit은 그 주/달 전체가 하나의 기간.
    public static func periodKey(for item: TodoItem, date: Date = Date(), calendar: Calendar = .current) -> String {
        switch item.type {
        case .task:
            return dateKey(for: date, calendar: calendar)
        case .habit:
            switch item.effectiveFrequency {
            case .daily: return dateKey(for: date, calendar: calendar)
            case .weekly: return weekKey(for: date, calendar: calendar)
            case .monthly: return monthKey(for: date, calendar: calendar)
            }
        }
    }

    public static func isVisibleToday(_ item: TodoItem, weekday: Int) -> Bool {
        switch item.type {
        case .task:
            return !item.isArchived
        case .habit:
            switch item.effectiveFrequency {
            case .weekly, .monthly:
                return true
            case .daily:
                guard let repeatDays = item.repeatDays else { return true }
                return repeatDays.contains(weekday)
            }
        }
    }

    /// 일회성 할일(task)은 완료해도 계속 남아 있다가 다음 "앱 기준 하루"(새벽 4시 이후)가 되면
    /// 사라져야 한다 — daily habit처럼 미완료로 되돌아가는 게 아니라 완전히 삭제.
    static func purgeStaleCompletedTasks(in context: ModelContext) {
        let today = dateKey(for: Date())
        guard let items = try? context.fetch(FetchDescriptor<TodoItem>()) else { return }
        guard let completions = try? context.fetch(FetchDescriptor<CompletionRecord>()) else { return }

        for item in items where item.type == .task {
            let itemId = item.id
            let itemCompletions = completions.filter { $0.todoId == itemId }
            guard !itemCompletions.isEmpty else { continue }
            let isStale = itemCompletions.allSatisfy { $0.date != today }
            if isStale {
                deleteTodoItem(item, in: context)
            }
        }
    }

    public static func sortedTodayList(_ items: [TodoItem], completedIds: Set<UUID>) -> [TodoItem] {
        items.sorted { lhs, rhs in
            let lhsDone = completedIds.contains(lhs.id)
            let rhsDone = completedIds.contains(rhs.id)
            if lhsDone != rhsDone {
                return !lhsDone
            }
            return lhs.createdAt < rhs.createdAt
        }
    }
}
