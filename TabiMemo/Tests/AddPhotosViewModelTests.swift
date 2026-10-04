import Domain
import Foundation
@testable import TabiMemo
import Testing

@MainActor
struct AddPhotosViewModelTests {
    private struct NoSuggestion: PhotoSuggesting {
        func suggest(from imageData: Data) async -> PhotoSuggestion? { nil }
    }

    private struct NoMetadata: PhotoMetadataReading {
        func read(from imageData: Data) -> PhotoMetadata { PhotoMetadata() }
    }

    private let photoRepository = FakePhotoRepository()
    private let existing = Fixtures.photo("existing", minutes: 10)

    private func makeViewModel(count: Int) -> AddPhotosViewModel {
        AddPhotosViewModel(
            count: count,
            trip: Fixtures.trip(photos: [existing]),
            fallbackCenter: Coordinate(latitude: 0, longitude: 0),
            readMetadata: ReadPhotoMetadataUseCase(reader: NoMetadata()),
            suggestText: SuggestPhotoTextUseCase(suggester: NoSuggestion()),
            addPhotos: AddPhotosUseCase(photoRepository: photoRepository)
        )
    }

    private func fill(_ draft: PhotoDraft, minutes: Double) {
        draft.imageData = Data([1])
        draft.coordinate = Coordinate(latitude: 1, longitude: 1)
        draft.takenAt = Fixtures.date(minutes: minutes)
    }

    @Test func reorderStartsInDateOrderIncludingExistingPhotos() {
        let viewModel = makeViewModel(count: 2)
        fill(viewModel.drafts[0], minutes: 20)
        fill(viewModel.drafts[1], minutes: 5)
        viewModel.prepareReorder()
        #expect(viewModel.entries.map(\.id) == [viewModel.drafts[1].id, existing.id, viewModel.drafts[0].id])
        #expect(viewModel.assignedDates == [5, 10, 20].map { Fixtures.date(minutes: $0) })
    }

    @Test func savingAfterReorderPassesTheOrder() {
        let viewModel = makeViewModel(count: 1)
        fill(viewModel.drafts[0], minutes: 20)
        viewModel.prepareReorder()
        // 新しい写真を、すでにある写真より前へ。
        viewModel.entries.move(fromOffsets: IndexSet(integer: 1), toOffset: 0)
        viewModel.save()
        #expect(photoRepository.takenAtChanges == [[existing.id: Fixtures.date(minutes: 20)]])
        #expect(photoRepository.added.first?.photos.first?.takenAt == Fixtures.date(minutes: 10))
    }

    @Test func cannotSaveUntilEveryPhotoHasALocation() {
        let viewModel = makeViewModel(count: 1)
        viewModel.drafts[0].imageData = Data([1])
        #expect(!viewModel.canSave)
        viewModel.drafts[0].coordinate = Coordinate(latitude: 1, longitude: 1)
        #expect(viewModel.canSave)
    }

    @Test func initialCenterUsesTheNeighboringPhoto() {
        let viewModel = makeViewModel(count: 1)
        viewModel.drafts[0].takenAt = Fixtures.date(minutes: 11)
        #expect(viewModel.initialCenter(for: viewModel.drafts[0]) == existing.coordinate)
    }
}
