import Foundation

public extension AsyncStream where Element: Sendable {
    /// 流れてくる値を変換した、新しいストリーム。受け取り側が止まると、元のストリームの購読も止まる。
    func map<T: Sendable>(_ transform: @escaping @Sendable (Element) -> T) -> AsyncStream<T> {
        AsyncStream<T> { continuation in
            let task = Task {
                for await element in self {
                    continuation.yield(transform(element))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
