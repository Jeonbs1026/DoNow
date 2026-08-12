import Foundation
import SwiftData

public enum SharedModelContainer {
    static let appGroupID = "group.com.jbs.MyDays.DoNow"

    /// ModelContainer 생성은 파일 I/O가 있는 무거운 작업이라 프로세스당 한 번만 만들어 재사용한다.
    /// (앱과 위젯 익스텐션은 별도 프로세스라 각자 자기 프로세스 안에서만 캐시됨 — 공유 불필요)
    public static let shared: ModelContainer = {
        let schema = Schema([TodoItem.self, CompletionRecord.self])
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("App Group container unavailable: \(appGroupID)")
        }
        let storeURL = groupURL.appendingPathComponent("DoNow.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
}
