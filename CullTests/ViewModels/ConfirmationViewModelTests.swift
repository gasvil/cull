import XCTest
@testable import Cull

@MainActor
final class ConfirmationViewModelTests: XCTestCase {

    var mockPhotoService: MockPhotoLibraryService!

    override func setUp() async throws {
        try await super.setUp()
        mockPhotoService = MockPhotoLibraryService()
    }

    override func tearDown() async throws {
        mockPhotoService = nil
        try await super.tearDown()
    }

    func testInitialState_isReady() {
        let sut = ConfirmationViewModel(
            markedPhotoIds: ["1", "2"],
            totalByteSize: 1024 * 1024 * 10,
            periodDescription: "Últimos 7 días",
            triageMode: .burst,
            photoLibraryService: mockPhotoService
        )

        XCTAssertEqual(sut.state, .ready)
        XCTAssertFalse(sut.isPurgeDisabled)
        XCTAssertEqual(sut.triageTypeDescription, "Tomas redundantes")
        XCTAssertEqual(sut.modeSubtitleText, "redundantes")
    }

    func testIsPurgeDisabled_whenEmpty_returnsTrue() {
        let sut = ConfirmationViewModel(
            markedPhotoIds: [],
            totalByteSize: 0,
            periodDescription: "Hoy",
            triageMode: .noFace,
            photoLibraryService: mockPhotoService
        )

        XCTAssertTrue(sut.isPurgeDisabled)
        XCTAssertEqual(sut.triageTypeDescription, "Fotos sin rostro")
        XCTAssertEqual(sut.modeSubtitleText, "sin rostro")
    }

    func testFormattedRecoverableSpace_formatsBytesAccurately() {
        let sut = ConfirmationViewModel(
            markedPhotoIds: ["1"],
            totalByteSize: 30_400_000,
            periodDescription: "Últimos 7 días",
            triageMode: .burst,
            photoLibraryService: mockPhotoService
        )

        XCTAssertFalse(sut.formattedRecoverableSpace.isEmpty)
        XCTAssertTrue(sut.formattedRecoverableSpace.contains("MB") || sut.formattedRecoverableSpace.contains("30"))
    }

    func testRequestPurge_whenDisabled_doesNotTransition() {
        let sut = ConfirmationViewModel(
            markedPhotoIds: [],
            totalByteSize: 0,
            periodDescription: "Hoy",
            triageMode: .burst,
            photoLibraryService: mockPhotoService
        )

        sut.requestPurge()
        XCTAssertEqual(sut.state, .ready)
    }

    func testRequestPurge_whenEnabled_transitionsToWarningModal() {
        let sut = ConfirmationViewModel(
            markedPhotoIds: ["1", "2"],
            totalByteSize: 1000,
            periodDescription: "Hoy",
            triageMode: .burst,
            photoLibraryService: mockPhotoService
        )

        sut.requestPurge()
        XCTAssertEqual(sut.state, .presentingWarningModal)

        sut.dismissWarningModal()
        XCTAssertEqual(sut.state, .ready)
    }

    func testConfirmPurge_whenNativePromptCancelled_returnsFalseAndResetsReady() async {
        let sut = ConfirmationViewModel(
            markedPhotoIds: ["1", "2"],
            totalByteSize: 1000,
            periodDescription: "Hoy",
            triageMode: .burst,
            photoLibraryService: mockPhotoService
        )

        // Simular que el usuario pulsa "Cancelar" en el diálogo nativo de iOS (EC-2)
        mockPhotoService.deleteAssetsResult = false

        let success = await sut.confirmPurge()

        XCTAssertFalse(success)
        XCTAssertEqual(sut.state, .ready)
    }

    func testConfirmPurge_whenPhotoKitConfirms_deletesAssetsAndTransitionsToCompleted() async {
        let sut = ConfirmationViewModel(
            markedPhotoIds: ["1", "2"],
            totalByteSize: 2000,
            periodDescription: "Últimos 7 días",
            triageMode: .burst,
            photoLibraryService: mockPhotoService
        )

        mockPhotoService.deleteAssetsResult = true

        let success = await sut.confirmPurge()

        XCTAssertTrue(success)
        XCTAssertEqual(sut.state, .completed)
        XCTAssertEqual(mockPhotoService.deletedAssetIds, ["1", "2"])
    }

    func testConfirmPurge_whenPhotoLibraryThrows_transitionsToError() async {
        let sut = ConfirmationViewModel(
            markedPhotoIds: ["1"],
            totalByteSize: 1000,
            periodDescription: "Hoy",
            triageMode: .burst,
            photoLibraryService: mockPhotoService
        )

        mockPhotoService.deleteAssetsError = AppError.operationFailed(description: "Fallo en PhotoKit")

        let success = await sut.confirmPurge()

        XCTAssertFalse(success)
        if case .error(let message) = sut.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Se esperaba estado .error")
        }
    }
}
