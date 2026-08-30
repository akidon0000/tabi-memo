import Foundation

/// Home の `NavigationStack` に積む画面遷移。
enum Route: Hashable {
    case tripDetail(Trip)
    case replay(Trip)
}
