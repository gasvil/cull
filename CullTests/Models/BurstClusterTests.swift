import XCTest
@testable import Cull

final class BurstClusterTests: XCTestCase {

    func testRecoverableByteSize_calculatesSumOfDiscardedItemsOnly() {
        // Arrange
        let asset1 = PhotoAsset(
            id: "photo-1",
            creationDate: Date(),
            pixelWidth: 4032,
            pixelHeight: 3024,
            byteSize: 3_000_000,
            isFavorite: false
        )
        let asset2 = PhotoAsset(
            id: "photo-2",
            creationDate: Date(),
            pixelWidth: 4032,
            pixelHeight: 3024,
            byteSize: 2_500_000,
            isFavorite: false
        )
        let asset3 = PhotoAsset(
            id: "photo-3",
            creationDate: Date(),
            pixelWidth: 4032,
            pixelHeight: 3024,
            byteSize: 2_000_000,
            isFavorite: false
        )

        let candidate1 = PhotoCandidate(asset: asset1)
        let candidate2 = PhotoCandidate(asset: asset2)
        let candidate3 = PhotoCandidate(asset: asset3)

        // Act: keeper is photo-1, discards are photo-2 and photo-3
        let cluster = BurstCluster(
            id: UUID(),
            items: [candidate1, candidate2, candidate3],
            keeperIds: ["photo-1"],
            discardIds: ["photo-2", "photo-3"],
            status: .pending
        )

        // Assert: recoverable size should be 2.5MB + 2.0MB = 4.5MB
        XCTAssertEqual(cluster.recoverableByteSize, 4_500_000)
    }

    func testIsAllDiscarded_returnsTrue_whenDiscardIdsEqualsItemsCount() {
        let asset1 = PhotoAsset(id: "1", creationDate: Date(), pixelWidth: 100, pixelHeight: 100, byteSize: 1000, isFavorite: false)
        let asset2 = PhotoAsset(id: "2", creationDate: Date(), pixelWidth: 100, pixelHeight: 100, byteSize: 1000, isFavorite: false)

        let cluster = BurstCluster(
            id: UUID(),
            items: [PhotoCandidate(asset: asset1), PhotoCandidate(asset: asset2)],
            keeperIds: [],
            discardIds: ["1", "2"],
            status: .pending
        )

        XCTAssertTrue(cluster.isAllDiscarded)
        XCTAssertFalse(cluster.isAllKept)
    }

    func testIsAllKept_returnsTrue_whenDiscardIdsIsEmpty() {
        let asset1 = PhotoAsset(id: "1", creationDate: Date(), pixelWidth: 100, pixelHeight: 100, byteSize: 1000, isFavorite: false)
        let asset2 = PhotoAsset(id: "2", creationDate: Date(), pixelWidth: 100, pixelHeight: 100, byteSize: 1000, isFavorite: false)

        let cluster = BurstCluster(
            id: UUID(),
            items: [PhotoCandidate(asset: asset1), PhotoCandidate(asset: asset2)],
            keeperIds: ["1", "2"],
            discardIds: [],
            status: .pending
        )

        XCTAssertTrue(cluster.isAllKept)
        XCTAssertFalse(cluster.isAllDiscarded)
        XCTAssertEqual(cluster.recoverableByteSize, 0)
    }
}
