import Foundation
import SwiftData

#if targetEnvironment(simulator)
public enum DoNowSampleData {
    public static func seedIfNeeded(in context: ModelContext) {
        guard (try? context.fetchCount(FetchDescriptor<TodoItem>())) == 0 else { return }
        let samples = [
            TodoItem(title: "물 마시기", type: .habit),
            TodoItem(title: "세탁소 찾기", type: .task),
            TodoItem(title: "택배 찾아오기", type: .task)
        ]
        samples.forEach { context.insert($0) }
        try? context.save()
    }
}
#endif
