import SwiftUI
import SwiftData

/// "오늘의 할일" 화면 — 미완료·완료 항목을 구분 없이 하나의 목록으로 표시 (완료 항목은 정렬상 하단에 위치).
public struct TodayListView: View {
    public init() {}

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \TodoItem.createdAt) private var allItems: [TodoItem]
    @Query private var allCompletions: [CompletionRecord]

    @State private var showingHabitEditor = false
    @State private var habitPendingDelete: TodoItem?
    @State private var memoTarget: TodoItem?

    private var todayWeekday: Int { TodayFilter.todayWeekday() }

    private var completedIdsToday: Set<UUID> {
        Set(allItems.filter { item in
            let key = TodayFilter.periodKey(for: item)
            return allCompletions.contains { $0.todoId == item.id && $0.date == key }
        }.map(\.id))
    }

    private func todayItems(completedIds: Set<UUID>) -> [TodoItem] {
        let visible = allItems.filter { TodayFilter.isVisibleToday($0, weekday: todayWeekday) }
        return TodayFilter.sortedTodayList(visible, completedIds: completedIds)
    }

    public var body: some View {
        // 렌더링 한 번에 한 번씩만 계산해서 아래에서 재사용 (완료 기록이 쌓일수록 반복 계산 비용이 커짐)
        let completedIds = completedIdsToday
        let items = todayItems(completedIds: completedIds)
        let doneCount = items.filter { completedIds.contains($0.id) }.count

        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header(doneCountLabel: "\(doneCount) / \(items.count) 완료")
                QuickAddBar()
                    .padding(.bottom, 22)

                if items.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(items) { item in
                            todoRow(item, isDone: completedIds.contains(item.id))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.defaultMinListRowHeight, 0)
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 22)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingHabitEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Color.appAccentText)
                }
            }
            .sheet(isPresented: $showingHabitEditor) {
                HabitEditorView()
            }
            .sheet(isPresented: Binding(
                get: { memoTarget != nil },
                set: { isPresented in
                    if !isPresented { memoTarget = nil }
                }
            )) {
                if let target = memoTarget {
                    MemoDetailView(item: target)
                }
            }
            .task {
                TodayFilter.purgeStaleCompletedTasks(in: modelContext)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    TodayFilter.purgeStaleCompletedTasks(in: modelContext)
                }
            }
            .alert(
                "반복 할일을 삭제할까요?",
                isPresented: Binding(
                    get: { habitPendingDelete != nil },
                    set: { isPresented in
                        if !isPresented { habitPendingDelete = nil }
                    }
                ),
                presenting: habitPendingDelete
            ) { habit in
                Button("삭제", role: .destructive) {
                    TodayFilter.deleteTodoItem(habit, in: modelContext)
                    habitPendingDelete = nil
                }
                Button("취소", role: .cancel) {
                    habitPendingDelete = nil
                }
            } message: { habit in
                Text("\"\(habit.title)\"을(를) 삭제하면 매일 목록에서 더 이상 나오지 않아요.")
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32, weight: .thin))
                .foregroundStyle(Color.appText.opacity(0.25))
            Text("오늘 할 일이 없어요")
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundStyle(Color.appText.opacity(0.85))
            Text("위 입력창에 할 일을 적거나 + 버튼으로 반복 할일을 추가해보세요")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Color.appText.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.top, 80)
        .frame(maxWidth: .infinity)
    }

    private func header(doneCountLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("오늘의 할일")
                .font(.system(size: 30, weight: .medium, design: .serif))
                .foregroundStyle(Color.appText)
            Text(doneCountLabel)
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Color.appText.opacity(0.55))
        }
        .padding(.bottom, 18)
    }

    private func todoRow(_ item: TodoItem, isDone: Bool) -> some View {
        TodoRow(
            item: item,
            isDone: isDone,
            onToggle: { toggle(item) },
            onMemoTap: { memoTarget = item }
        )
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.appBackground)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                requestDelete(item)
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    private func toggle(_ item: TodoItem) {
        withAnimation(.easeInOut(duration: 0.25)) {
            TodayFilter.toggleCompletion(todoId: item.id, dateKey: TodayFilter.periodKey(for: item), in: modelContext)
        }
    }

    private func requestDelete(_ item: TodoItem) {
        if item.type == .habit {
            habitPendingDelete = item
        } else {
            TodayFilter.deleteTodoItem(item, in: modelContext)
        }
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let isDone: Bool
    let onToggle: () -> Void
    let onMemoTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                HStack(spacing: 14) {
                    checkCircle
                    Text(item.title)
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(Color.appText)
                        .strikethrough(isDone)
                        .opacity(isDone ? 0.4 : 1)
                        .animation(.easeInOut(duration: 0.2), value: isDone)
                    if item.type == .habit {
                        Image(systemName: "repeat")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appText.opacity(0.45))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(item.type == .habit ? "\(item.title), 반복 할일" : item.title)
            .accessibilityValue(isDone ? "완료" : "미완료")

            Button(action: onMemoTap) {
                Image(systemName: (item.memo?.isEmpty ?? true) ? "square.and.pencil" : "note.text")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appText.opacity(0.4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("메모")
        }
        .padding(.vertical, 13)
        .overlay(Rectangle().fill(Color.appDivider).frame(height: 1), alignment: .bottom)
    }

    private var checkCircle: some View {
        ZStack {
            Circle()
                .strokeBorder(isDone ? Color.appAccent : Color.appDivider, lineWidth: 1.5)
            if isDone {
                Circle().fill(Color.appAccent)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.appBackground)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 22, height: 22)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDone)
    }
}
