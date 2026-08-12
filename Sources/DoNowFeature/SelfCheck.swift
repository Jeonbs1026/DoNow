import Foundation
import SwiftData

#if DEBUG
public func runTodayFilterSelfCheck() {
    var sundayComponents = DateComponents()
    sundayComponents.year = 2026; sundayComponents.month = 7; sundayComponents.day = 26; sundayComponents.hour = 12
    let sunday = Calendar.current.date(from: sundayComponents)!
    assert(TodayFilter.todayWeekday(now: sunday) == 0, "일요일은 weekday 0이어야 함")

    var mondayComponents = DateComponents()
    mondayComponents.year = 2026; mondayComponents.month = 7; mondayComponents.day = 20; mondayComponents.hour = 12
    let monday = Calendar.current.date(from: mondayComponents)!
    assert(TodayFilter.todayWeekday(now: monday) == 1, "월요일은 weekday 1이어야 함")

    let dailyHabit = TodoItem(title: "Exercise", type: .habit)
    assert(TodayFilter.isVisibleToday(dailyHabit, weekday: 3) == true, "매일 반복 habit은 항상 노출되어야 함")

    let mondayOnlyHabit = TodoItem(title: "Gym", type: .habit, repeatDays: [1])
    assert(TodayFilter.isVisibleToday(mondayOnlyHabit, weekday: 1) == true, "월요일 habit은 월요일에 노출")
    assert(TodayFilter.isVisibleToday(mondayOnlyHabit, weekday: 2) == false, "월요일 habit은 화요일엔 숨김")

    let archivedTask = TodoItem(title: "Old", type: .task)
    archivedTask.isArchived = true
    assert(TodayFilter.isVisibleToday(archivedTask, weekday: 0) == false, "archived task는 숨겨야 함")

    let a = TodoItem(title: "A", type: .task)
    let b = TodoItem(title: "B", type: .task)
    let sorted = TodayFilter.sortedTodayList([a, b], completedIds: [a.id])
    assert(sorted.first?.id == b.id, "미완료 항목이 완료 항목보다 앞에 와야 함")

    // 하루 경계는 자정이 아니라 새벽 4시
    var mondayEarlyComponents = DateComponents()
    mondayEarlyComponents.year = 2026; mondayEarlyComponents.month = 7; mondayEarlyComponents.day = 27; mondayEarlyComponents.hour = 2
    let mondayEarly = Calendar.current.date(from: mondayEarlyComponents)!
    assert(TodayFilter.todayWeekday(now: mondayEarly) == 0, "새벽 4시 이전(2시)은 전날(일요일)로 취급되어야 함")
    assert(TodayFilter.dateKey(for: mondayEarly) == TodayFilter.dateKey(for: sunday), "새벽 4시 이전 dateKey는 전날과 같아야 함")

    var mondayAtStartComponents = DateComponents()
    mondayAtStartComponents.year = 2026; mondayAtStartComponents.month = 7; mondayAtStartComponents.day = 27; mondayAtStartComponents.hour = 4
    let mondayAtStart = Calendar.current.date(from: mondayAtStartComponents)!
    assert(TodayFilter.todayWeekday(now: mondayAtStart) == 1, "새벽 4시 정각부터는 그날(월요일)로 취급되어야 함")

    // weekly/monthly habit은 하루가 아니라 그 주/달 전체가 완료 판정 단위
    // 주의 시작 요일은 로케일마다 다르므로(예: ko_KR은 일요일 시작), 비교 대상은
    // 하드코딩된 날짜가 아니라 mondayAtStart에서 하루만 더한 날짜로 구해야 항상 같은 주가 보장된다.
    let weeklyHabit = TodoItem(title: "빨래", type: .habit, frequency: .weekly)
    let mondayKey = TodayFilter.periodKey(for: weeklyHabit, date: mondayAtStart)
    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: mondayAtStart)!
    assert(TodayFilter.periodKey(for: weeklyHabit, date: nextDay) == mondayKey, "같은 주의 다른 요일은 같은 주간 키를 가져야 함")
    assert(TodayFilter.isVisibleToday(weeklyHabit, weekday: 3) == true, "weekly habit은 요일과 무관하게 매일 노출되어야 함")

    let monthlyHabit = TodoItem(title: "정산", type: .habit, frequency: .monthly)
    var earlyAugustComponents = DateComponents()
    earlyAugustComponents.year = 2026; earlyAugustComponents.month = 8; earlyAugustComponents.day = 1; earlyAugustComponents.hour = 12
    let earlyAugust = Calendar.current.date(from: earlyAugustComponents)!
    var lateAugustComponents = DateComponents()
    lateAugustComponents.year = 2026; lateAugustComponents.month = 8; lateAugustComponents.day = 30; lateAugustComponents.hour = 12
    let lateAugust = Calendar.current.date(from: lateAugustComponents)!
    assert(
        TodayFilter.periodKey(for: monthlyHabit, date: earlyAugust) == TodayFilter.periodKey(for: monthlyHabit, date: lateAugust),
        "같은 달의 다른 날짜는 같은 월간 키를 가져야 함"
    )

    // task는 항상 그날의 dateKey를 완료 판정 단위로 사용 (daily habit과 동일)
    let task = TodoItem(title: "정리", type: .task)
    assert(TodayFilter.periodKey(for: task, date: nextDay) == TodayFilter.dateKey(for: nextDay), "task의 기간 키는 dateKey와 같아야 함")

    // 완료한 지난 앱-기준-하루의 일회성 task는 삭제되고, 오늘 완료했거나 아직 미완료인 건 남아야 함
    let testConfig = ModelConfiguration(isStoredInMemoryOnly: true)
    let testContainer = try! ModelContainer(for: TodoItem.self, CompletionRecord.self, configurations: testConfig)
    let testContext = ModelContext(testContainer)

    let doneYesterday = TodoItem(title: "어제 완료", type: .task)
    testContext.insert(doneYesterday)
    testContext.insert(CompletionRecord(todoId: doneYesterday.id, date: "2000-01-01"))

    let doneToday = TodoItem(title: "오늘 완료", type: .task)
    testContext.insert(doneToday)
    testContext.insert(CompletionRecord(todoId: doneToday.id, date: TodayFilter.dateKey(for: Date())))

    let notDone = TodoItem(title: "미완료", type: .task)
    testContext.insert(notDone)

    TodayFilter.purgeStaleCompletedTasks(in: testContext)
    let remainingIds = Set(((try? testContext.fetch(FetchDescriptor<TodoItem>())) ?? []).map(\.id))
    assert(!remainingIds.contains(doneYesterday.id), "지난 앱-기준-하루에 완료한 task는 삭제되어야 함")
    assert(remainingIds.contains(doneToday.id), "오늘 완료한 task는 남아있어야 함")
    assert(remainingIds.contains(notDone.id), "미완료 task는 삭제되면 안 됨")
}
#endif
