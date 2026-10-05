import Domain
import Foundation

/// 並べ替え画面の1行。地図にすでにある写真と、これから保存する写真が同じ並びに入る。
@MainActor
enum ReorderEntry: Identifiable {
    case existing(Photo)
    case new(PhotoDraft)

    var id: UUID {
        switch self {
        case .existing(let photo): photo.id
        case .new(let draft): draft.id
        }
    }

    var imageData: Data? {
        switch self {
        case .existing(let photo): photo.imageData
        case .new(let draft): draft.imageData
        }
    }

    var title: String {
        switch self {
        case .existing(let photo): photo.title
        case .new(let draft): draft.title
        }
    }

    var takenAt: Date {
        switch self {
        case .existing(let photo): photo.takenAt
        case .new(let draft): draft.takenAt
        }
    }

    var isNew: Bool {
        if case .new = self { true } else { false }
    }
}
