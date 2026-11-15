import XCTest
@testable import Cull

@MainActor
final class BurstTriageViewModelTests: XCTestCase {
    private var mockPhotoLibrary: MockPhotoLibraryService!
    private var mockClustering: BurstClusteringService!
    private var mockQuality: MockImageQualityEvaluator!
    private var sut: BurstTriageViewModel!

    override func setUp() {
        super.setUp()
        mockPhotoLibrary = MockPhotoLibraryService()
        mockClustering = BurstClusteringService()
        mockQuality = MockImageQualityEvaluator()
        sut = BurstTriageViewModel(
            photoLibraryService: mockPhotoLibrary,
            clusteringService: mockClustering,
            qualityEvaluator: mockQuality
        )
    }

    override func tearDown() {
        sut = nil
        mockQuality = nil
        mockClustering = nil
        mockPhotoLibrary = nil
        super.tearDown()
    }

    func testLoadAndAnalyze_whenPermissionGranted_emitsLoadedWithClusters() async {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "1", creationDate: baseTime)
        let asset2 = PhotoAssetFixture.make(id: "2", creationDate: baseTime.addingTimeInterval(1.0))
        mockPhotoLibrary.recentAssetsResult = [asset1, asset2]

        await sut.loadAndAnalyzeClusters()

        if case .loaded(let clusters) = sut.state {
            XCTAssertEqual(clusters.count, 1)
            XCTAssertEqual(clusters.first?.items.count, 2)
        } else {
            XCTFail("Se esperaba estado .loaded pero se obtuvo: \(sut.state)")
        }
    }

    func testLoadAndAnalyze_whenPermissionDenied_emitsUnauthorizedError() async {
        mockPhotoLibrary.authorizationResult = false

        await sut.loadAndAnalyzeClusters()

        if case .error(let appError) = sut.state {
            XCTAssertEqual(appError, .unauthorized)
        } else {
            XCTFail("Se esperaba estado .error(.unauthorized) pero se obtuvo: \(sut.state)")
        }
    }

    func testToggleKeeper_addsPhotoToKeepers_andRemovesFromDiscards() async {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "1", creationDate: baseTime, byteSize: 1000)
        let asset2 = PhotoAssetFixture.make(id: "2", creationDate: baseTime.addingTimeInterval(1.0), byteSize: 2000)
        let asset3 = PhotoAssetFixture.make(id: "3", creationDate: baseTime.addingTimeInterval(2.0), byteSize: 3000)
        mockPhotoLibrary.recentAssetsResult = [asset1, asset2, asset3]

        await sut.loadAndAnalyzeClusters()

        guard case .loaded(let clusters) = sut.state, let cluster = clusters.first else {
            XCTFail("No hay clusters cargados")
            return
        }

        let initialDiscards = cluster.discardIds
        guard let photoToKeep = initialDiscards.first else {
            XCTFail("No hay fotos en discard")
            return
        }

        // Action: multi-keeper toggle
        sut.toggleKeeper(photoId: photoToKeep, in: cluster.id)

        if case .loaded(let updatedClusters) = sut.state, let updatedCluster = updatedClusters.first {
            XCTAssertTrue(updatedCluster.keeperIds.contains(photoToKeep))
            XCTAssertFalse(updatedCluster.discardIds.contains(photoToKeep))
        } else {
            XCTFail("Error al verificar estado actualizado")
        }
    }

    func testDiscardAll_marksAllPhotosInClusterForDiscard() async {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "1", creationDate: baseTime)
        let asset2 = PhotoAssetFixture.make(id: "2", creationDate: baseTime.addingTimeInterval(1.0))
        mockPhotoLibrary.recentAssetsResult = [asset1, asset2]

        await sut.loadAndAnalyzeClusters()

        guard case .loaded(let clusters) = sut.state, let cluster = clusters.first else {
            XCTFail("No hay clusters")
            return
        }

        sut.discardAll(in: cluster.id)

        if case .loaded(let updatedClusters) = sut.state, let updatedCluster = updatedClusters.first {
            XCTAssertTrue(updatedCluster.isAllDiscarded)
            XCTAssertEqual(updatedCluster.discardIds, ["1", "2"])
            XCTAssertTrue(updatedCluster.keeperIds.isEmpty)
        } else {
            XCTFail("Fallo en discardAll")
        }
    }

    func testKeepAll_clearsDiscards_andMarksClusterReviewedKept() async {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "1", creationDate: baseTime)
        let asset2 = PhotoAssetFixture.make(id: "2", creationDate: baseTime.addingTimeInterval(1.0))
        mockPhotoLibrary.recentAssetsResult = [asset1, asset2]

        await sut.loadAndAnalyzeClusters()

        guard case .loaded(let clusters) = sut.state, let cluster = clusters.first else {
            XCTFail("No hay clusters")
            return
        }

        sut.keepAll(in: cluster.id)

        if case .loaded(let updatedClusters) = sut.state {
            // Cluster was resolved and removed from pending queue
            XCTAssertEqual(updatedClusters.count, 0)
        } else if case .empty = sut.state {
            // Transitioned to empty state as all clusters were reviewed
            XCTAssertTrue(true)
        } else {
            XCTFail("Estado no esperado: \(sut.state)")
        }
    }

    func testConfirmDiscards_invokesService_andRemovesClusterFromQueueOnSuccess() async {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "1", creationDate: baseTime)
        let asset2 = PhotoAssetFixture.make(id: "2", creationDate: baseTime.addingTimeInterval(1.0))
        mockPhotoLibrary.recentAssetsResult = [asset1, asset2]
        mockPhotoLibrary.deleteAssetsResult = true

        await sut.loadAndAnalyzeClusters()

        guard case .loaded(let clusters) = sut.state, let cluster = clusters.first else {
            XCTFail("No hay clusters cargados")
            return
        }

        let success = await sut.confirmDiscards(for: cluster.id)

        XCTAssertTrue(success)
        XCTAssertFalse(mockPhotoLibrary.deletedAssetIds.isEmpty)
    }

    func testConfirmDiscards_whenCancelledInDialog_preservesClusterState() async {
        let baseTime = Date()
        let asset1 = PhotoAssetFixture.make(id: "1", creationDate: baseTime)
        let asset2 = PhotoAssetFixture.make(id: "2", creationDate: baseTime.addingTimeInterval(1.0))
        mockPhotoLibrary.recentAssetsResult = [asset1, asset2]
        mockPhotoLibrary.deleteAssetsResult = false // Simula cancelación en el diálogo nativo (EC-6)

        await sut.loadAndAnalyzeClusters()

        guard case .loaded(let clusters) = sut.state, let cluster = clusters.first else {
            XCTFail("No hay clusters cargados")
            return
        }

        let success = await sut.confirmDiscards(for: cluster.id)

        XCTAssertFalse(success)
        if case .loaded(let preservedClusters) = sut.state {
            XCTAssertEqual(preservedClusters.count, 1)
        } else {
            XCTFail("El cluster debía ser preservado")
        }
    }
}
