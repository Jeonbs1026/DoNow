import SwiftUI
import SwiftData

private enum RepeatMode: String, CaseIterable, Identifiable {
    case daily = "매일"
    case customDays = "요일 선택"
    case weekly = "주 1회"
    case monthly = "월 1회"

    var id: String { rawValue }
}

struct HabitEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var repeatMode: RepeatMode = .daily
    @State private var selectedDays: Set<Int> = []

    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
    private let weekdayFullNames = ["일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일"]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("반복 할일")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .tracking(1)
                    .foregroundStyle(Color.appAccentText)
                    .padding(.bottom, 18)

                Text("이름")
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(Color.appText.opacity(0.55))
                    .padding(.bottom, 6)
                TextField("예: 운동, 독서", text: $title)
                    .font(.system(size: 16, design: .serif))
                    .foregroundStyle(Color.appText)
                    .padding(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appDivider, lineWidth: 1)
                    )
                    .padding(.bottom, 28)

                Text("반복 주기")
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(Color.appText.opacity(0.55))
                    .padding(.bottom, 4)

                Picker("반복 주기", selection: $repeatMode.animation(.easeInOut(duration: 0.2))) {
                    ForEach(RepeatMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Color.appAccent)
                .padding(.vertical, 11)

                if repeatMode == .customDays {
                    weekdayChipRow
                        .padding(.top, 2)
                        .padding(.bottom, 11)
                }

                resetInfoRow

                Spacer()
            }
            .padding(26)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(Color.appText.opacity(0.55))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: save)
                        .foregroundStyle(Color.appAccentText)
                        .disabled(
                            title.trimmingCharacters(in: .whitespaces).isEmpty
                                || (repeatMode == .customDays && selectedDays.isEmpty)
                        )
                }
            }
        }
    }

    private var weekdayChipRow: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { day in
                weekdayChip(day)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func weekdayChip(_ day: Int) -> some View {
        let isSelected = selectedDays.contains(day)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                if isSelected { selectedDays.remove(day) } else { selectedDays.insert(day) }
            }
        } label: {
            Text(weekdaySymbols[day])
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(isSelected ? Color.appBackground : Color.appText.opacity(0.55))
                .frame(width: 40, height: 40)
                .background(Circle().fill(isSelected ? Color.appAccent : Color.clear))
                .overlay(Circle().strokeBorder(isSelected ? Color.clear : Color.appDivider, lineWidth: 1.5))
                .shadow(color: Color.appAccent.opacity(isSelected ? 0.35 : 0), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(weekdayFullNames[day])
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// 반복 주기 선택에 곧바로 이어지는 설명 — "새벽 4시가 하루 경계"라는 앱 규칙이
    /// 주기마다 실제로 언제 초기화되는지 사용자가 헷갈리지 않도록 즉시 보여준다.
    private var resetInfoText: String {
        switch repeatMode {
        case .daily:
            return "매일 새벽 4시에 초기화돼요"
        case .customDays:
            return "선택한 요일에만 표시되고, 새벽 4시에 초기화돼요"
        case .weekly:
            let resetDay = weekdaySymbols[Calendar.current.firstWeekday - 1]
            return "매주 \(resetDay)요일 새벽 4시에 초기화돼요"
        case .monthly:
            return "매달 1일 새벽 4시에 초기화돼요"
        }
    }

    private var resetInfoRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "sunrise")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.appAccent)
            Text(resetInfoText)
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(Color.appText.opacity(0.5))
        }
        .padding(.top, 14)
        .overlay(Rectangle().fill(Color.appDivider).frame(height: 1), alignment: .top)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard repeatMode != .customDays || !selectedDays.isEmpty else { return }

        let frequency: RepeatFrequency
        let repeatDays: [Int]?
        switch repeatMode {
        case .daily:
            frequency = .daily
            repeatDays = nil
        case .customDays:
            frequency = .daily
            repeatDays = Array(selectedDays).sorted()
        case .weekly:
            frequency = .weekly
            repeatDays = nil
        case .monthly:
            frequency = .monthly
            repeatDays = nil
        }

        modelContext.insert(TodoItem(title: trimmed, type: .habit, repeatDays: repeatDays, frequency: frequency))
        TodayFilter.commitChange(in: modelContext)
        dismiss()
    }
}
