import SwiftUI
import UIKit

private extension UIColor {
    /// 라이트/다크 모드에 따라 다른 색을 내는 UIColor. Asset Catalog 없이 코드만으로 관리.
    convenience init(light: UIColor, dark: UIColor) {
        self.init { $0.userInterfaceStyle == .dark ? dark : light }
    }
}

public extension Color {
    /// 완료 표시 전용 색. 앱 tint와 무관하게 항상 초록(iOS Reminders 등과 동일한 관례)으로 고정.
    /// 홈 화면 위젯(TodayWidget)의 진행률 링에서 사용.
    static let todoComplete = Color.green

    // MARK: - "오늘의 할일" 1c 시안 디자인 토큰 (design_handoff_todo_list/README.md)
    // 라이트: 크림 배경 위 따뜻한 뉴트럴. 다크: 같은 팔레트를 반전한 웜 차콜 + 밝힌 골드.
    static let appBackground = Color(UIColor(
        light: UIColor(red: 0.953, green: 0.949, blue: 0.949, alpha: 1), // #f3f2f2
        dark: UIColor(red: 0.106, green: 0.098, blue: 0.090, alpha: 1) // #1b1917
    ))
    static let appText = Color(UIColor(
        light: UIColor(red: 0.126, green: 0.122, blue: 0.114, alpha: 1), // #201f1d
        dark: UIColor(red: 0.949, green: 0.941, blue: 0.929, alpha: 1) // #f2f0ed
    ))
    static let appAccent = Color(UIColor(
        light: UIColor(red: 0.714, green: 0.510, blue: 0.208, alpha: 1), // #b68235
        dark: UIColor(red: 0.847, green: 0.663, blue: 0.361, alpha: 1) // #d8a95c, 어두운 배경에서 대비 확보용으로 밝힘
    ))
    static let appAccentText = Color(UIColor(
        light: UIColor(red: 0.522, green: 0.373, blue: 0.153, alpha: 1), // 텍스트용 진한 톤
        dark: UIColor(red: 0.902, green: 0.729, blue: 0.427, alpha: 1) // 텍스트용 밝은 톤
    ))
    static let appDivider = Color.appText.opacity(0.12) // hairline, appText를 따라가므로 자동으로 다크 대응
}
