import XCTest
import Photos
@testable import Cull

final class PhotoLibraryServiceTests: XCTestCase {

    func testMockPhotoLibraryService_conformsToProtocolAndReturnsConfiguredValues() async throws {
        let mock = MockPhotoLibraryService()
        mock.authorizationResult = true
        let asset1 = PhotoAssetFixture.make(id: "photo-1")
        mock.recentAssetsResult = [asset1]

        let isAuth = await mock.requestAuthorization()
        XCTAssertTrue(isAuth)
        XCTAssertEqual(mock.requestedAuthCount, 1)

        let fetched = try await mock.fetchRecentAssets(limit: 10)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, "photo-1")
        XCTAssertEqual(mock.fetchRecentAssetsLimit, 10)

        let deleteSuccess = try await mock.deleteAssets(withIDs: ["photo-1"])
        XCTAssertTrue(deleteSuccess)
        XCTAssertEqual(mock.deletedAssetIds, ["photo-1"])
    }

    func testDeleteAssets_whenEmptyIDs_returnsTrueWithoutCallingAPI() async throws {
        let service = PhotoLibraryService()
        let result = try await service.deleteAssets(withIDs: [])
        XCTAssertTrue(result)
    }

    func testFetchImageData_whenAssetNotFound_throwsResourceNotFound() async {
        let service = PhotoLibraryService()

        do {
            _ = try await service.fetchImageData(for: "non-existent-id-12345", targetSize: CGSize(width: 100, height: 100))
            XCTFail("Se esperaba AppError.resourceNotFound")
        } catch let error as AppError {
            if case .resourceNotFound(let id) = error {
                XCTAssertEqual(id, "non-existent-id-12345")
            } else {
                XCTFail("Error inesperado: \(error)")
            }
        } catch {
            XCTFail("Tipo de error no esperado: \(error)")
        }
    }
}
