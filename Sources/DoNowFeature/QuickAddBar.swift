import SwiftUI
import SwiftData

struct QuickAddBar: View {
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            TextField("할 일을 입력하세요", text: $title)
                .font(.system(size: 14, design: .serif))
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit(addTask)
            Button("추가", action: addTask)
                .font(.system(size: 13, design: .serif))
                .buttonStyle(.plain)
                .foregroundStyle(Color.appAccentText)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appDivider, lineWidth: 1)
        )
        .onReceive(NotificationCenter.default.publisher(for: .focusQuickAdd)) { _ in
            isFocused = true
        }
        .task {
            // Cold launch: the delegate may have posted .focusQuickAdd before this
            // view's .onReceive subscription existed. Sticky flag catches that.
            guard NightlyReminder.pendingFocus else { return }
            NightlyReminder.pendingFocus = false
            isFocused = true
        }
    }

    private func addTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(TodoItem(title: trimmed, type: .task))
        TodayFilter.commitChange(in: modelContext)
        title = ""
    }
}
