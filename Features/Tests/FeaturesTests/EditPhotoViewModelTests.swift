import Domain
import Foundation
@testable import EditPhotoFeature
import Testing
import TestSupport

@MainActor
struct EditPhotoViewModelTests {
    @Test func savingPassesTheEditedValues() {
        let repository = FakePhotoRepository()
        let photo = Fixtures.photo("before", minutes: 1)
        let viewModel = EditPhotoViewModel(photo: photo, updatePhoto: UpdatePhotoUseCase(photoRepository: repository))
        viewModel.edit.title = "after"
        viewModel.setLocation(Coordinate(latitude: 2, longitude: 3))
        viewModel.save()

        let saved = repository.updated.first
        #expect(saved?.photoID == photo.id)
        #expect(saved?.edit.title == "after")
        #expect(saved?.edit.coordinate == Coordinate(latitude: 2, longitude: 3))
        #expect(saved?.edit.isLocationManuallyPlaced == true)
    }
}
