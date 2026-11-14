import XCTest
@testable import Cull

final class HomeViewModelTests: XCTestCase {
    @MainActor
    func testLoadInitialData_SetsLoadedStateWithItems() {
        let sut = HomeViewModel()

        XCTAssertEqual(sut.state, .idle)

        sut.loadInitialData()

        if case .loaded(let items) = sut.state {
            XCTAssertFalse(items.isEmpty)
            XCTAssertEqual(items.count, 2)
        } else {
            XCTFail("Se esperaba estado .loaded pero se obtuvo \(sut.state)")
        }
    }

    @MainActor
    func testAddItem_ValidTitle_AppendsItem() throws {
        let sut = HomeViewModel()
        sut.loadInitialData()

        try sut.addItem(title: "Nuevo Ítem", subtitle: "Descripción del ítem")

        if case .loaded(let items) = sut.state {
            XCTAssertEqual(items.count, 3)
            XCTAssertEqual(items.last?.title, "Nuevo Ítem")
        } else {
            XCTFail("Se esperaba estado .loaded")
        }
    }

    @MainActor
    func testAddItem_EmptyTitle_ThrowsTypedError() {
        let sut = HomeViewModel()
        sut.loadInitialData()

        XCTAssertThrowsError(try sut.addItem(title: "   ", subtitle: "Test")) { error in
            guard let appError = error as? AppError,
                  case .invalidInput = appError else {
                XCTFail("Se esperaba AppError.invalidInput pero se obtuvo \(error)")
                return
            }
        }
    }
}
