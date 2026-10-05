import Foundation
import SwiftData

/// SwiftData の保存先。App はこの型を作って Repository に渡すだけで、SwiftData を直接 import しない。
public final class SwiftDataStore {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    private init(inMemory: Bool) throws {
        let schema = Schema([TripRecord.self, PhotoRecord.self, LocationPointRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        container = try ModelContainer(for: schema, configurations: configuration)
    }

    /// 端末に保存する。
    public static func live() throws -> SwiftDataStore {
        try SwiftDataStore(inMemory: false)
    }

    /// メモリ上だけに置く(テスト・プレビュー用)。
    public static func inMemory() throws -> SwiftDataStore {
        try SwiftDataStore(inMemory: true)
    }

    /// 1件もなければ、デモのトリップを入れる(初回起動で画面が空にならないように)。
    public func seedSampleTripIfEmpty() throws {
        guard try context.fetchCount(FetchDescriptor<TripRecord>()) == 0 else { return }
        context.insert(SampleTrip.make())
        try context.save()
    }
}

/// Repository が対象を見つけられなかった。
public enum SwiftDataStoreError: Error, Equatable {
    case tripNotFound(UUID)
}
