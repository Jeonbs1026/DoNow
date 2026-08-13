import SwiftUI
import SwiftData
import UIKit

struct MemoDetailView: View {
    let item: TodoItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(item: TodoItem) {
        self.item = item
        _text = State(initialValue: item.memo ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("메모")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .tracking(1)
                    .foregroundStyle(Color.appAccentText)
                    .padding(.bottom, 4)
                Text(item.title)
                    .font(.system(size: 24, weight: .medium, design: .serif))
                    .foregroundStyle(Color.appText)
                    .padding(.bottom, 18)

                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("메모를 입력하세요")
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(Color.appText.opacity(0.35))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    TextEditor(text: $text)
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(Color.appText)
                        .scrollContentBackground(.hidden)
                }
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appDivider, lineWidth: 1)
                )
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
                    Button("완료") {
                        item.memo = text.isEmpty ? nil : text
                        TodayFilter.commitChange(in: modelContext)
                        dismiss()
                    }
                    .foregroundStyle(Color.appAccentText)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") { hideKeyboard() }
                }
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
