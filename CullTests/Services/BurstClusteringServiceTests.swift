import XCTest
@testable import Cull

final class BurstClusteringServiceTests: XCTestCase {
    private var sut: BurstClusteringService!

    override func setUp() {
        super.setUp()
        sut = BurstClusteringService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testClusterize_groupsPhotosWithin5SecondsInterval() {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "1", creationDate: baseTime)
        let asset2 = PhotoAssetFixture.make(id: "2", creationDate: baseTime.addingTimeInterval(2.0))
        let asset3 = PhotoAssetFixture.make(id: "3", creationDate: baseTime.addingTimeInterval(4.5))

        let clusters = sut.clusterize(assets: [asset1, asset2, asset3], timeThresholdSeconds: 5.0)

        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters.first?.items.count, 3)
    }

    func testClusterize_separatesPhotosWithIntervalGreaterThan5Seconds() {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "1", creationDate: baseTime)
        let asset2 = PhotoAssetFixture.make(id: "2", creationDate: baseTime.addingTimeInterval(6.0))

        let clusters = sut.clusterize(assets: [asset1, asset2], timeThresholdSeconds: 5.0)

        // Neither forms a cluster of >= 2 within 5 seconds, so 0 clusters (EC-1)
        XCTAssertEqual(clusters.count, 0)
    }

    func testClusterize_groupsNativeBurstWithSameIdentifierRegardlessOfTime() {
        let baseTime = Date()
        let burstId = "burst-xyz-123"
        let asset1 = PhotoAssetFixture.make(id: "1", creationDate: baseTime, burstIdentifier: burstId, representsBurst: true)
        let asset2 = PhotoAssetFixture.make(id: "2", creationDate: baseTime.addingTimeInterval(10.0), burstIdentifier: burstId, representsBurst: true)

        let clusters = sut.clusterize(assets: [asset1, asset2], timeThresholdSeconds: 5.0)

        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters.first?.items.count, 2)
    }

    func testClusterize_designatesSinglePhotoWithHighestCompositeScoreAsKeeper() {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "1", creationDate: baseTime)
        let asset2 = PhotoAssetFixture.make(id: "2", creationDate: baseTime.addingTimeInterval(1.0))
        let asset3 = PhotoAssetFixture.make(id: "3", creationDate: baseTime.addingTimeInterval(2.0))

        let candidate1 = PhotoCandidate(asset: asset1, assessment: QualityAssessment(sharpnessScore: 0.5, exposureScore: 0.5, compositeScore: 0.50))
        let candidate2 = PhotoCandidate(asset: asset2, assessment: QualityAssessment(sharpnessScore: 0.95, exposureScore: 0.9, compositeScore: 0.94))
        let candidate3 = PhotoCandidate(asset: asset3, assessment: QualityAssessment(sharpnessScore: 0.7, exposureScore: 0.7, compositeScore: 0.70))

        let clusters = sut.clusterize(candidates: [candidate1, candidate2, candidate3], timeThresholdSeconds: 5.0)

        XCTAssertEqual(clusters.count, 1)
        guard let cluster = clusters.first else { return }
        XCTAssertEqual(cluster.keeperIds, ["2"])
        XCTAssertEqual(cluster.discardIds, ["1", "3"])
    }

    func testClusterize_resolvesTiesBySelectingOldestPhoto() {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "oldest", creationDate: baseTime)
        let asset2 = PhotoAssetFixture.make(id: "newer", creationDate: baseTime.addingTimeInterval(1.0))

        let assessmentTie = QualityAssessment(sharpnessScore: 0.85, exposureScore: 0.85, compositeScore: 0.85)
        let candidate1 = PhotoCandidate(asset: asset1, assessment: assessmentTie)
        let candidate2 = PhotoCandidate(asset: asset2, assessment: assessmentTie)

        let clusters = sut.clusterize(candidates: [candidate1, candidate2], timeThresholdSeconds: 5.0)

        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters.first?.keeperIds, ["oldest"])
        XCTAssertEqual(clusters.first?.discardIds, ["newer"])
    }

    func testClusterize_preselectsNonKeeperPhotosAsDiscardCandidates() {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "1", creationDate: baseTime)
        let asset2 = PhotoAssetFixture.make(id: "2", creationDate: baseTime.addingTimeInterval(1.0))

        let candidate1 = PhotoCandidate(asset: asset1, assessment: QualityAssessment(sharpnessScore: 0.9, exposureScore: 0.9, compositeScore: 0.9))
        let candidate2 = PhotoCandidate(asset: asset2, assessment: QualityAssessment(sharpnessScore: 0.4, exposureScore: 0.4, compositeScore: 0.4))

        let clusters = sut.clusterize(candidates: [candidate1, candidate2], timeThresholdSeconds: 5.0)

        guard let cluster = clusters.first else {
            XCTFail("Cluster no generado")
            return
        }
        XCTAssertTrue(cluster.keeperIds.contains("1"))
        XCTAssertTrue(cluster.discardIds.contains("2"))
        XCTAssertFalse(cluster.discardIds.contains("1"))
    }

    func testClusterize_neverPreselectsFavoritePhotosForDiscard() {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "best", creationDate: baseTime, isFavorite: false)
        let asset2 = PhotoAssetFixture.make(id: "favorite-lower-score", creationDate: baseTime.addingTimeInterval(1.0), isFavorite: true)
        let asset3 = PhotoAssetFixture.make(id: "normal-lower-score", creationDate: baseTime.addingTimeInterval(2.0), isFavorite: false)

        let candidate1 = PhotoCandidate(asset: asset1, assessment: QualityAssessment(sharpnessScore: 0.95, exposureScore: 0.95, compositeScore: 0.95))
        let candidate2 = PhotoCandidate(asset: asset2, assessment: QualityAssessment(sharpnessScore: 0.60, exposureScore: 0.60, compositeScore: 0.60))
        let candidate3 = PhotoCandidate(asset: asset3, assessment: QualityAssessment(sharpnessScore: 0.50, exposureScore: 0.50, compositeScore: 0.50))

        let clusters = sut.clusterize(candidates: [candidate1, candidate2, candidate3], timeThresholdSeconds: 5.0)

        guard let cluster = clusters.first else {
            XCTFail("Cluster no generado")
            return
        }
        XCTAssertEqual(cluster.keeperIds, ["best"])
        // favorite-lower-score MUST NOT be in discardIds (FR-7)
        XCTAssertFalse(cluster.discardIds.contains("favorite-lower-score"))
        XCTAssertTrue(cluster.discardIds.contains("normal-lower-score"))
    }

    func testClusterize_marksClusterAllKept_whenAllPhotosAreFavorites() {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "fav-1", creationDate: baseTime, isFavorite: true)
        let asset2 = PhotoAssetFixture.make(id: "fav-2", creationDate: baseTime.addingTimeInterval(1.0), isFavorite: true)

        let clusters = sut.clusterize(assets: [asset1, asset2], timeThresholdSeconds: 5.0)

        guard let cluster = clusters.first else {
            XCTFail("Cluster no generado")
            return
        }
        XCTAssertTrue(cluster.isAllKept)
        XCTAssertEqual(cluster.discardIds.count, 0)
    }
}
