import XCTest
@testable import Cull

@MainActor
final class HomeAndModeSelectionTests: XCTestCase {

    var mockPhotoService: MockPhotoLibraryService!
    var homeVM: HomeViewModel!

    override func setUp() async throws {
        try await super.setUp()
        mockPhotoService = MockPhotoLibraryService()
        homeVM = HomeViewModel(photoLibraryService: mockPhotoService)
    }

    override func tearDown() async throws {
        homeVM = nil
        mockPhotoService = nil
        try await super.tearDown()
    }

    // MARK: - PeriodSelectionModels Tests

    func testPeriodOption_metadata() {
        XCTAssertEqual(PeriodOption.allCases.count, 4)
        XCTAssertEqual(PeriodOption.today.title, "Hoy")
        XCTAssertEqual(PeriodOption.last7Days.title, "Últimos 7 días")
        XCTAssertEqual(PeriodOption.thisMonth.title, "Este mes")
        XCTAssertEqual(PeriodOption.custom.title, "Personalizado")

        XCTAssertFalse(PeriodOption.today.systemImage.isEmpty)
        XCTAssertFalse(PeriodOption.last7Days.systemImage.isEmpty)
    }

    func testTriageMode_metadata() {
        XCTAssertEqual(TriageMode.allCases.count, 2)

        let burst = TriageMode.burst
        XCTAssertEqual(burst.title, "Ráfagas")
        XCTAssertEqual(burst.badgeTitle, "SMART PICK")
        XCTAssertFalse(burst.description.isEmpty)

        let noFace = TriageMode.noFace
        XCTAssertEqual(noFace.title, "Sin Rostro")
        XCTAssertEqual(noFace.badgeTitle, "3 CATEGORÍAS")
        XCTAssertFalse(noFace.description.isEmpty)
    }

    // MARK: - HomeViewModel Tests (Scenario 1 & 2)

    func testHomeViewModel_initialSelectionIsLast7Days() {
        XCTAssertEqual(homeVM.selectedPeriod, .last7Days)
    }

    func testHomeViewModel_selectPeriod_updatesSelection() {
        homeVM.selectPeriod(.today)
        XCTAssertEqual(homeVM.selectedPeriod, .today)

        homeVM.selectPeriod(.thisMonth)
        XCTAssertEqual(homeVM.selectedPeriod, .thisMonth)

        homeVM.selectPeriod(.custom)
        XCTAssertEqual(homeVM.selectedPeriod, .custom)
    }

    func testHomeViewModel_resolveCurrentDateRange_handlesAllOptions() {
        // Hoy
        homeVM.selectedPeriod = .today
        let todayRange = homeVM.resolveCurrentDateRange()
        XCTAssertTrue(Calendar.current.isDateInToday(todayRange.start))

        // Últimos 7 días
        homeVM.selectedPeriod = .last7Days
        let last7Range = homeVM.resolveCurrentDateRange()
        XCTAssertLessThanOrEqual(last7Range.start, last7Range.end)

        // Este mes
        homeVM.selectedPeriod = .thisMonth
        let monthRange = homeVM.resolveCurrentDateRange()
        XCTAssertLessThanOrEqual(monthRange.start, monthRange.end)

        // Personalizado Día Único
        let testDate = Calendar.current.date(byAdding: .day, value: -12, to: Date())!
        homeVM.selectedPeriod = .custom
        homeVM.customDateMode = .singleDate
        homeVM.selectedSingleDate = testDate
        let singleRange = homeVM.resolveCurrentDateRange()
        XCTAssertTrue(Calendar.current.isDate(singleRange.start, inSameDayAs: testDate))

        // Personalizado Rango
        homeVM.customDateMode = .dateRange
        let start = Calendar.current.date(byAdding: .day, value: -20, to: Date())!
        let end = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        homeVM.selectedStartDate = start
        homeVM.selectedEndDate = end
        let customRange = homeVM.resolveCurrentDateRange()
        XCTAssertLessThanOrEqual(customRange.start, customRange.end)

        // EC-2: Normalización si fecha inicio > fecha fin
        homeVM.selectedStartDate = end
        homeVM.selectedEndDate = start
        let normalizedRange = homeVM.resolveCurrentDateRange()
        XCTAssertLessThanOrEqual(normalizedRange.start, normalizedRange.end)
    }

    func testHomeViewModel_asyncPhotoCount_updatesSubtitle() async {
        mockPhotoService.assetCountResult = 245
        homeVM.selectPeriod(.last7Days)

        // Esperar a que la tarea asíncrona resuelva
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(homeVM.activePhotoCount, 245)
        let subtitle = homeVM.subtitle(for: .last7Days)
        XCTAssertTrue(subtitle.contains("~245 fotos"))
    }

    // MARK: - ModeSelectionViewModel Tests (Scenario 3, 4, 5)

    func testModeSelectionViewModel_defaultIsBurst() {
        let sut = ModeSelectionViewModel(startDate: Date(), endDate: Date())
        XCTAssertEqual(sut.selectedMode, .burst)
    }

    func testModeSelectionViewModel_selectMode_switchesModeExclusively() {
        let sut = ModeSelectionViewModel(startDate: Date(), endDate: Date())

        sut.selectMode(.noFace)
        XCTAssertEqual(sut.selectedMode, .noFace)

        sut.selectMode(.burst)
        XCTAssertEqual(sut.selectedMode, .burst)
    }

    func testModeSelectionViewModel_startAnalysis_burst_configuresEnvironmentAndNavigates() {
        let router = AppRouter()
        let env = AppEnvironment(
            router: router,
            photoLibraryService: mockPhotoService
        )
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let end = Date()
        let sut = ModeSelectionViewModel(startDate: start, endDate: end)

        sut.selectMode(.burst)
        sut.startAnalysis(environment: env)

        XCTAssertEqual(router.path.count, 1)

        let burstVM = env.makeBurstTriageViewModel()
        let range = burstVM.resolveCurrentDateRange()
        XCTAssertEqual(Calendar.current.startOfDay(for: range.start), Calendar.current.startOfDay(for: start))
    }

    func testModeSelectionViewModel_startAnalysis_noFace_configuresEnvironmentAndNavigates() {
        let router = AppRouter()
        let env = AppEnvironment(
            router: router,
            photoLibraryService: mockPhotoService
        )
        let start = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let end = Date()
        let sut = ModeSelectionViewModel(startDate: start, endDate: end)

        sut.selectMode(.noFace)
        sut.startAnalysis(environment: env)

        XCTAssertEqual(router.path.count, 1)

        let noFaceVM = env.makeNoFaceTriageViewModel()
        let range = noFaceVM.resolveCurrentDateRange()
        XCTAssertEqual(Calendar.current.startOfDay(for: range.start), Calendar.current.startOfDay(for: start))
    }
}
