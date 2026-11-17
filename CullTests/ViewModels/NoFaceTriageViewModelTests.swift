import XCTest
@testable import Cull

@MainActor
final class NoFaceTriageViewModelTests: XCTestCase {

    var mockPhotoService: MockPhotoLibraryService!
    var mockClassifier: MockFacelessClassificationService!
    var sut: NoFaceTriageViewModel!

    override func setUp() async throws {
        try await super.setUp()
        mockPhotoService = MockPhotoLibraryService()
        mockClassifier = MockFacelessClassificationService()
        sut = NoFaceTriageViewModel(
            photoLibraryService: mockPhotoService,
            classifierService: mockClassifier
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockClassifier = nil
        mockPhotoService = nil
        try await super.tearDown()
    }

    // MARK: - Initial State & Date Selection

    func testPrepareView_setsSelectingDateWhenIdle() {
        XCTAssertEqual(sut.state, .idle)
        sut.prepareView()
        XCTAssertEqual(sut.state, .selectingDate)
    }

    func testChangeDateFilter_transitionsBackToSelectingDate() {
        sut.changeDateFilter()
        XCTAssertEqual(sut.state, .selectingDate)
    }

    func testResolveCurrentDateRange_handlesAllModes() {
        sut.filterMode = .today
        let todayRange = sut.resolveCurrentDateRange()
        XCTAssertTrue(Calendar.current.isDateInToday(todayRange.start))

        sut.filterMode = .yesterday
        let yesterdayRange = sut.resolveCurrentDateRange()
        XCTAssertTrue(Calendar.current.isDateInYesterday(yesterdayRange.start))

        sut.filterMode = .last7Days
        let last7Range = sut.resolveCurrentDateRange()
        XCTAssertLessThanOrEqual(last7Range.start, last7Range.end)

        let testDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        sut.filterMode = .singleDate
        sut.selectedSingleDate = testDate
        let singleRange = sut.resolveCurrentDateRange()
        XCTAssertTrue(Calendar.current.isDate(singleRange.start, inSameDayAs: testDate))

        sut.filterMode = .dateRange
        sut.selectedStartDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        sut.selectedEndDate = Date()
        let customRange = sut.resolveCurrentDateRange()
        XCTAssertLessThanOrEqual(customRange.start, customRange.end)
    }

    // MARK: - Authorization and Empty States

    func testLoadAndAnalyze_whenUnauthorized_setsErrorState() async {
        mockPhotoService.authorizationResult = false

        await sut.loadAndAnalyze()

        XCTAssertEqual(sut.state, .error(.unauthorized))
    }

    func testLoadAndAnalyze_whenNoAssetsInPeriod_setsEmptyState() async {
        mockPhotoService.recentAssetsResult = []

        await sut.loadAndAnalyze()

        if case .empty(let reason) = sut.state {
            XCTAssertTrue(reason.contains("No se encontraron fotos"))
        } else {
            XCTFail("Expected empty state, got \(sut.state)")
        }
    }

    func testLoadAndAnalyze_whenAllAssetsAreFavorites_excludesAllAndSetsEmptyState() async {
        let favorite1 = PhotoAssetFixture.make(id: "fav-1", isFavorite: true)
        let favorite2 = PhotoAssetFixture.make(id: "fav-2", isFavorite: true)
        mockPhotoService.recentAssetsResult = [favorite1, favorite2]

        await sut.loadAndAnalyze()

        if case .empty(let reason) = sut.state {
            XCTAssertTrue(reason.contains("protegidas como favoritas"))
        } else {
            XCTFail("Expected empty state with favorites protection, got \(sut.state)")
        }
    }

    func testLoadAndAnalyze_whenAllPhotosHaveFaces_setsEmptyState() async {
        let photo1 = PhotoAssetFixture.make(id: "face-1")
        mockPhotoService.recentAssetsResult = [photo1]
        mockPhotoService.imageDataResolver = { $0.data(using: .utf8)! }

        await mockClassifier.setResult(
            FacelessClassificationResult(hasFaces: true, category: nil),
            forAssetId: "face-1"
        )

        await sut.loadAndAnalyze()

        if case .empty(let reason) = sut.state {
            XCTAssertTrue(reason.contains("No se encontraron fotos sin personas"))
        } else {
            XCTFail("Expected empty state, got \(sut.state)")
        }
    }

    // MARK: - Classification, Preselection & Scenario 1

    func testLoadAndAnalyze_semanticClassificationAndPreselection() async {
        let util1 = PhotoAssetFixture.make(id: "u1", byteSize: 2_000_000)
        let util2 = PhotoAssetFixture.make(id: "u2", byteSize: 3_000_000)
        let def1 = PhotoAssetFixture.make(id: "d1", byteSize: 4_000_000)
        let val1 = PhotoAssetFixture.make(id: "v1", byteSize: 5_000_000)
        let val2 = PhotoAssetFixture.make(id: "v2", byteSize: 6_000_000)
        let val3 = PhotoAssetFixture.make(id: "v3", byteSize: 7_000_000)

        mockPhotoService.recentAssetsResult = [util1, util2, def1, val1, val2, val3]
        mockPhotoService.imageDataResolver = { $0.data(using: .utf8)! }

        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .utilitarian), forAssetId: "u1")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .utilitarian), forAssetId: "u2")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .deficient), forAssetId: "d1")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .toValidate), forAssetId: "v1")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .toValidate), forAssetId: "v2")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .toValidate), forAssetId: "v3")

        await sut.loadAndAnalyze()

        guard case .loaded(let groups) = sut.state else {
            XCTFail("Expected loaded state, got \(sut.state)")
            return
        }

        // Scenario 1: Utilitarias (2) y Deficientes (1) preseleccionadas; Por Validar (3) desmarcadas
        let utilGroup = groups.first { $0.category == .utilitarian }!
        let defGroup = groups.first { $0.category == .deficient }!
        let valGroup = groups.first { $0.category == .toValidate }!

        XCTAssertEqual(utilGroup.totalCount, 2)
        XCTAssertEqual(utilGroup.selectedCount, 2)
        XCTAssertTrue(utilGroup.allSelected)

        XCTAssertEqual(defGroup.totalCount, 1)
        XCTAssertEqual(defGroup.selectedCount, 1)
        XCTAssertTrue(defGroup.allSelected)

        XCTAssertEqual(valGroup.totalCount, 3)
        XCTAssertEqual(valGroup.selectedCount, 0)
        XCTAssertTrue(valGroup.noneSelected)

        XCTAssertEqual(sut.totalCandidatesCount, 6)
        XCTAssertEqual(sut.totalSelectedCount, 3)
        // 2MB + 3MB + 4MB = 9MB
        XCTAssertEqual(sut.totalRecoverableByteSize, 9_000_000)
    }

    // MARK: - Scenario 2: Ocultamiento estricto de Favoritas

    func testLoadAndAnalyze_strictFavoriteImmunity() async {
        let docFavorite = PhotoAssetFixture.make(id: "doc-fav", isFavorite: true)
        let landscapeNormal = PhotoAssetFixture.make(id: "landscape-normal", isFavorite: false)

        mockPhotoService.recentAssetsResult = [docFavorite, landscapeNormal]
        mockPhotoService.imageDataResolver = { $0.data(using: .utf8)! }

        await mockClassifier.setResult(
            FacelessClassificationResult(hasFaces: false, category: .toValidate),
            forAssetId: "landscape-normal"
        )

        await sut.loadAndAnalyze()

        guard case .loaded(let groups) = sut.state else {
            XCTFail("Expected loaded state, got \(sut.state)")
            return
        }

        let allCandidateIds = groups.flatMap { $0.candidates.map(\.id) }
        XCTAssertFalse(allCandidateIds.contains("doc-fav"))
        XCTAssertTrue(allCandidateIds.contains("landscape-normal"))
        XCTAssertEqual(sut.totalCandidatesCount, 1)
    }

    // MARK: - Scenario 8: Categorías Vacías con Conteo Explícito Cero (FR-13, EC-4)

    func testLoadAndAnalyze_emptyCategory_reflectsExplicitZeroCount() async {
        let u1 = PhotoAssetFixture.make(id: "u1")
        let v1 = PhotoAssetFixture.make(id: "v1")
        mockPhotoService.recentAssetsResult = [u1, v1]
        mockPhotoService.imageDataResolver = { $0.data(using: .utf8)! }

        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .utilitarian), forAssetId: "u1")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .toValidate), forAssetId: "v1")

        await sut.loadAndAnalyze()

        guard case .loaded(let groups) = sut.state else {
            XCTFail("Expected loaded state, got \(sut.state)")
            return
        }

        XCTAssertEqual(groups.count, 3)

        let defGroup = groups.first { $0.category == .deficient }
        XCTAssertNotNil(defGroup)
        XCTAssertEqual(defGroup?.totalCount, 0)
        XCTAssertEqual(defGroup?.selectedCount, 0)
    }

    // MARK: - Scenario 3 & 4: Toggling and Dynamic Byte Size (FR-8, FR-10)

    func testToggleSelection_updatesSelectedCountAndRecoverableByteSize() async {
        let u1 = PhotoAssetFixture.make(id: "u1", byteSize: 2_000_000)
        let v1 = PhotoAssetFixture.make(id: "v1", byteSize: 5_000_000)
        mockPhotoService.recentAssetsResult = [u1, v1]
        mockPhotoService.imageDataResolver = { $0.data(using: .utf8)! }

        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .utilitarian), forAssetId: "u1")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .toValidate), forAssetId: "v1")

        await sut.loadAndAnalyze()

        XCTAssertEqual(sut.totalSelectedCount, 1) // u1 preselected
        XCTAssertEqual(sut.totalRecoverableByteSize, 2_000_000)

        // Scenario 3: Deseleccionar u1
        sut.toggleSelection(candidateId: "u1")
        XCTAssertEqual(sut.totalSelectedCount, 0)
        XCTAssertEqual(sut.totalRecoverableByteSize, 0)

        // Scenario 4: Seleccionar v1
        sut.toggleSelection(candidateId: "v1")
        XCTAssertEqual(sut.totalSelectedCount, 1)
        XCTAssertEqual(sut.totalRecoverableByteSize, 5_000_000)
    }

    // MARK: - Scenario 5: Bulk Selection (FR-9)

    func testBulkSelection_selectAllAndDeselectAll() async {
        let v1 = PhotoAssetFixture.make(id: "v1")
        let v2 = PhotoAssetFixture.make(id: "v2")
        mockPhotoService.recentAssetsResult = [v1, v2]
        mockPhotoService.imageDataResolver = { $0.data(using: .utf8)! }

        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .toValidate), forAssetId: "v1")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .toValidate), forAssetId: "v2")

        await sut.loadAndAnalyze()

        // Por Validar inicia con 0 seleccionadas
        XCTAssertEqual(sut.totalSelectedCount, 0)

        sut.selectAll(in: .toValidate)
        XCTAssertEqual(sut.totalSelectedCount, 2)

        sut.deselectAll(in: .toValidate)
        XCTAssertEqual(sut.totalSelectedCount, 0)
    }

    // MARK: - Scenario 6 & 7: Confirm Discards & System Dialog Cancel (FR-11, EC-5)

    func testConfirmDiscards_whenConfirmed_deletesAssetsAndUpdatesGroups() async {
        let u1 = PhotoAssetFixture.make(id: "u1")
        let v1 = PhotoAssetFixture.make(id: "v1")
        mockPhotoService.recentAssetsResult = [u1, v1]
        mockPhotoService.imageDataResolver = { $0.data(using: .utf8)! }

        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .utilitarian), forAssetId: "u1")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .toValidate), forAssetId: "v1")

        await sut.loadAndAnalyze()

        let success = await sut.confirmDiscards()
        XCTAssertTrue(success)
        XCTAssertEqual(mockPhotoService.deletedAssetIds, ["u1"])
        XCTAssertEqual(sut.totalCandidatesCount, 1)
        XCTAssertEqual(sut.totalSelectedCount, 0)
    }

    func testConfirmDiscards_whenUserCancels_preservesSelectionWithoutChanges() async {
        let u1 = PhotoAssetFixture.make(id: "u1")
        mockPhotoService.recentAssetsResult = [u1]
        mockPhotoService.imageDataResolver = { $0.data(using: .utf8)! }
        mockPhotoService.deleteAssetsResult = false // Simula cancelación en diálogo nativo

        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .utilitarian), forAssetId: "u1")

        await sut.loadAndAnalyze()

        let success = await sut.confirmDiscards()
        XCTAssertFalse(success)

        guard case .loaded(let groups) = sut.state else {
            XCTFail("Expected loaded state preserved, got \(sut.state)")
            return
        }

        let utilGroup = groups.first { $0.category == .utilitarian }!
        XCTAssertEqual(utilGroup.selectedCount, 1)
    }

    // MARK: - Scenario 9: Cache and Restoration (FR-12, EC-7)

    func testCacheRestoration_whenFiltersAndLibraryAreUnchanged_avoidsReanalysis() async {
        let u1 = PhotoAssetFixture.make(id: "u1")
        mockPhotoService.recentAssetsResult = [u1]
        mockPhotoService.imageDataResolver = { $0.data(using: .utf8)! }

        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .utilitarian), forAssetId: "u1")

        // 1er Análisis
        await sut.loadAndAnalyze()
        let callCountFirst = await mockClassifier.classifyCallCount
        XCTAssertEqual(callCountFirst, 1)

        // 2do Acceso con mismos filtros y mismas fotos
        await sut.loadAndAnalyze()
        let callCountSecond = await mockClassifier.classifyCallCount
        // No debe re-analizar (FR-12, EC-7)
        XCTAssertEqual(callCountSecond, 1)

        // Si se fuerza la recarga con forceRefresh = true
        await sut.loadAndAnalyze(forceRefresh: true)
        let callCountThird = await mockClassifier.classifyCallCount
        XCTAssertEqual(callCountThird, 2)
    }

    // MARK: - Redesign: Tabs and Bulk Selection (FR-4 to FR-7, FR-15, FR-16)

    func testSelectCategory_updatesSelectedCategoryTab() {
        XCTAssertEqual(sut.selectedCategory, .utilitarian)

        sut.selectCategory(.toValidate)
        XCTAssertEqual(sut.selectedCategory, .toValidate)

        sut.selectCategory(.deficient)
        XCTAssertEqual(sut.selectedCategory, .deficient)
    }

    func testToggleCategoryBulkSelection_whenAllSelected_deselectsAll() async {
        let u1 = PhotoAssetFixture.make(id: "u1")
        let u2 = PhotoAssetFixture.make(id: "u2")
        mockPhotoService.recentAssetsResult = [u1, u2]
        mockPhotoService.imageDataResolver = { $0.data(using: .utf8)! }

        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .utilitarian), forAssetId: "u1")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .utilitarian), forAssetId: "u2")

        await sut.loadAndAnalyze()

        XCTAssertTrue(sut.isAllSelected(in: .utilitarian))

        // Al estar todas seleccionadas, la acción masiva las desmarca todas
        sut.toggleCategoryBulkSelection(for: .utilitarian)
        XCTAssertFalse(sut.isAllSelected(in: .utilitarian))
        XCTAssertEqual(sut.group(for: .utilitarian)?.selectedCount, 0)
    }

    func testToggleCategoryBulkSelection_whenPartialSelected_selectsAll() async {
        let u1 = PhotoAssetFixture.make(id: "u1")
        let u2 = PhotoAssetFixture.make(id: "u2")
        mockPhotoService.recentAssetsResult = [u1, u2]
        mockPhotoService.imageDataResolver = { $0.data(using: .utf8)! }

        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .utilitarian), forAssetId: "u1")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .utilitarian), forAssetId: "u2")

        await sut.loadAndAnalyze()

        // Desmarcamos 1 foto (selección parcial: 1 de 2)
        sut.toggleSelection(candidateId: "u1")
        XCTAssertFalse(sut.isAllSelected(in: .utilitarian))
        XCTAssertEqual(sut.group(for: .utilitarian)?.selectedCount, 1)

        // Con selección parcial, la acción masiva marca todas
        sut.toggleCategoryBulkSelection(for: .utilitarian)
        XCTAssertTrue(sut.isAllSelected(in: .utilitarian))
        XCTAssertEqual(sut.group(for: .utilitarian)?.selectedCount, 2)
    }

    func testAllSelectedCandidateIds_aggregatesAcrossCategories() async {
        let u1 = PhotoAssetFixture.make(id: "u1")
        let d1 = PhotoAssetFixture.make(id: "d1")
        let v1 = PhotoAssetFixture.make(id: "v1")
        mockPhotoService.recentAssetsResult = [u1, d1, v1]
        mockPhotoService.imageDataResolver = { $0.data(using: .utf8)! }

        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .utilitarian), forAssetId: "u1")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .deficient), forAssetId: "d1")
        await mockClassifier.setResult(FacelessClassificationResult(hasFaces: false, category: .toValidate), forAssetId: "v1")

        await sut.loadAndAnalyze()

        // u1 y d1 preseleccionadas por defecto, v1 desmarcada
        XCTAssertEqual(sut.allSelectedCandidateIds.count, 2)
        XCTAssertTrue(sut.allSelectedCandidateIds.contains("u1"))
        XCTAssertTrue(sut.allSelectedCandidateIds.contains("d1"))

        // Marcamos v1
        sut.toggleSelection(candidateId: "v1")
        XCTAssertEqual(sut.allSelectedCandidateIds.count, 3)
    }
}
