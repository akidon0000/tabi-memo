import Foundation
import FoundationModels
import ImageIO

/// 画像から作る、タイトル案と解説。
struct PhotoSuggestion: Equatable {
    var title: String
    var description: String
}

@available(iOS 27.0, *)
@Generable
private struct GeneratedSuggestion {
    @Guide(description: "写真の内容を表す、15文字以内の短い日本語のタイトル")
    var title: String
    @Guide(description: "写真に写っているものと雰囲気を、旅の記録として2〜3文で書いた日本語の解説")
    var description: String
}

/// 端末内モデルを先に試し、使えなければ Private Cloud Compute に切り替える。どちらも使えなければ nil(提案欄を出さない)。
enum PhotoSuggestionService {
    static func suggest(from imageData: Data) async -> PhotoSuggestion? {
        guard #available(iOS 27.0, *), let image = downsampled(imageData) else { return nil }

        let onDevice = SystemLanguageModel.default
        if onDevice.availability == .available, onDevice.capabilities.contains(.vision),
           let result = try? await generate(with: onDevice, image: image) {
            return result
        }

        let cloud = PrivateCloudComputeLanguageModel()
        if cloud.availability == .available, !cloud.quotaUsage.isLimitReached {
            return try? await generate(with: cloud, image: image)
        }
        return nil
    }

    @available(iOS 27.0, *)
    private static func generate(with model: some LanguageModel, image: CGImage) async throws -> PhotoSuggestion {
        let session = LanguageModelSession(
            model: model,
            instructions: "あなたは旅行の記録を手伝うアシスタントです。写真を見て、日本語でタイトルと解説を作ります。写真から読み取れないことは書きません。"
        )
        let response = try await session.respond(generating: GeneratedSuggestion.self) {
            "この写真のタイトルと解説を作ってください。"
            Attachment(image)
        }
        return PhotoSuggestion(title: response.content.title, description: response.content.description)
    }

    /// モデルへ渡す前に縮小する(向きは反映済み)。
    private static func downsampled(_ data: Data, maxPixel: Int = 1024) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ] as CFDictionary)
    }
}
