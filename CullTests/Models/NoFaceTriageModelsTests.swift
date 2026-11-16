import XCTest
@testable import Cull

final class NoFaceTriageModelsTests: XCTestCase {

    func testFacelessCategory_metadataAndPreselectionFlags() {
        XCTAssertEqual(FacelessCategory.allCases.count, 3)

        let utilitarian = FacelessCategory.utilitarian
        XCTAssertEqual(utilitarian.title, "Utilitarias")
        XCTAssertFalse(utilitarian.subtitle.isEmpty)
        XCTAssertEqual(utilitarian.systemImage, "doc.text.viewfinder")
        XCTAssertTrue(utilitarian.defaultPreselected)

        let deficient = FacelessCategory.deficient
        XCTAssertEqual(deficient.title, "Deficientes")
        XCTAssertFalse(deficient.subtitle.isEmpty)
        XCTAssertEqual(deficient.systemImage, "camera.metering.unknown")
        XCTAssertTrue(deficient.defaultPreselected)

        let toValidate = FacelessCategory.toValidate
        XCTAssertEqual(toValidate.title, "Por Validar")
        XCTAssertFalse(toValidate.subtitle.isEmpty)
        XCTAssertEqual(toValidate.systemImage, "questionmark.circle")
        XCTAssertFalse(toValidate.defaultPreselected)
    }

    func testFacelessPhotoCandidate_initializationAndId() {
        let asset = PhotoAssetFixture.make(id: "photo-123", byteSize: 4_000_000)
        let candidate = FacelessPhotoCandidate(
            asset: asset,
            category: .utilitarian,
            textDetectedCount: 5,
            sharpnessScore: 0.7,
            luminanceScore: 0.6,
            isSelected: true
        )

        XCTAssertEqual(candidate.id, "photo-123")
        XCTAssertEqual(candidate.category, .utilitarian)
        XCTAssertEqual(candidate.textDetectedCount, 5)
        XCTAssertEqual(candidate.sharpnessScore, 0.7)
        XCTAssertEqual(candidate.luminanceScore, 0.6)
        XCTAssertTrue(candidate.isSelected)
    }

    func testFacelessTriageGroup_emptyMetrics() {
        let emptyGroup = FacelessTriageGroup(category: .deficient, candidates: [])

        XCTAssertEqual(emptyGroup.id, "deficient")
        XCTAssertEqual(emptyGroup.totalCount, 0)
        XCTAssertEqual(emptyGroup.selectedCount, 0)
        XCTAssertFalse(emptyGroup.allSelected)
        XCTAssertTrue(emptyGroup.noneSelected)
        XCTAssertEqual(emptyGroup.recoverableByteSize, 0)
    }

    func testFacelessTriageGroup_selectionMetricsAndByteSize() {
        let asset1 = PhotoAssetFixture.make(id: "1", byteSize: 2_000_000)
        let asset2 = PhotoAssetFixture.make(id: "2", byteSize: 3_000_000)
        let asset3 = PhotoAssetFixture.make(id: "3", byteSize: 5_000_000)

        let candidate1 = FacelessPhotoCandidate(asset: asset1, category: .utilitarian, isSelected: true)
        let candidate2 = FacelessPhotoCandidate(asset: asset2, category: .utilitarian, isSelected: false)
        let candidate3 = FacelessPhotoCandidate(asset: asset3, category: .utilitarian, isSelected: true)

        let group = FacelessTriageGroup(category: .utilitarian, candidates: [candidate1, candidate2, candidate3])

        XCTAssertEqual(group.totalCount, 3)
        XCTAssertEqual(group.selectedCount, 2)
        XCTAssertFalse(group.allSelected)
        XCTAssertFalse(group.noneSelected)
        // 2_000_000 + 5_000_000
        XCTAssertEqual(group.recoverableByteSize, 7_000_000)
    }

    func testFacelessTriageGroup_allSelectedTrueWhenAllAreSelected() {
        let asset1 = PhotoAssetFixture.make(id: "1", byteSize: 1_000_000)
        let candidate1 = FacelessPhotoCandidate(asset: asset1, category: .deficient, isSelected: true)
        let group = FacelessTriageGroup(category: .deficient, candidates: [candidate1])

        XCTAssertTrue(group.allSelected)
        XCTAssertFalse(group.noneSelected)
    }
}
