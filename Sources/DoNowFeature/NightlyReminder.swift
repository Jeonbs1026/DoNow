import Foundation
import UserNotifications

public extension Notification.Name {
    static let focusQuickAdd = Notification.Name("focusQuickAdd")
}

public enum NightlyReminder {
    public static let identifier = "nightlyTaskReminder"

    /// Set by the notification delegate when a cold launch should focus QuickAddBar.
    /// QuickAddBar consumes this once via `.task` since it may install its
    /// `.onReceive` subscription after the delegate has already posted.
    public static var pendingFocus = false

    static var triggerDateComponents: DateComponents {
        var components = DateComponents()
        components.hour = 21
        components.minute = 0
        return components
    }

    static var content: UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "오늘의 기록"
        content.body = "해야 할 일을 적어두세요"
        content.sound = .default
        return content
    }

    /// Requests notification authorization and, only once it resolves as granted,
    /// schedules the daily reminder. Scheduling must not race the (async) auth
    /// request — calling it unconditionally right after requestAuthorization()
    /// returns can hit `.notDetermined` and silently fail.
    public static func requestAuthorizationAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            #if DEBUG
            if let error {
                print("NightlyReminder authorization failed: \(error)")
            }
            #endif
            guard granted else { return }
            scheduleDaily()
        }
    }

    static func scheduleDaily() {
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error {
                print("NightlyReminder scheduling failed: \(error)")
            }
            #endif
        }
    }
}

final class NightlyReminderDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == NightlyReminder.identifier {
            // 이 델리게이트 콜백은 메인 스레드가 보장되지 않는다 — QuickAddBar의
            // .task/.onReceive는 MainActor에서 동작하니 여기서도 메인 스레드로 맞춰야 한다.
            DispatchQueue.main.async {
                NightlyReminder.pendingFocus = true
                NotificationCenter.default.post(name: .focusQuickAdd, object: nil)
            }
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

#if DEBUG
public func runNightlyReminderSelfCheck() {
    let components = NightlyReminder.triggerDateComponents
    assert(components.hour == 21, "알림 시각은 21시여야 함")
    assert(components.minute == 0, "알림 분은 0이어야 함")

    let content = NightlyReminder.content
    assert(content.title == "오늘의 기록", "알림 제목이 일치해야 함")
    assert(content.body == "해야 할 일을 적어두세요", "알림 본문이 일치해야 함")

    assert(NightlyReminder.identifier == "nightlyTaskReminder", "알림 identifier가 고정값이어야 함")

    let trigger = UNCalendarNotificationTrigger(dateMatching: NightlyReminder.triggerDateComponents, repeats: true)
    assert(trigger.repeats, "매일 반복되어야 함")
    assert(Calendar.current.component(.hour, from: trigger.nextTriggerDate()!) == 21, "다음 발송 시각은 21시여야 함")
}
#endif
