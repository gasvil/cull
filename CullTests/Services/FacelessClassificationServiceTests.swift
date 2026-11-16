import XCTest
import CoreGraphics
import UIKit
@testable import Cull

final class FacelessClassificationServiceTests: XCTestCase {

    var sut: FacelessClassificationService!

    override func setUp() async throws {
        try await super.setUp()
        sut = FacelessClassificationService()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func testClassify_emptyData_returnsNeutralResult() async throws {
        let result = try await sut.classify(imageData: Data())

        XCTAssertFalse(result.hasFaces)
        XCTAssertEqual(result.category, .toValidate)
    }

    func testClassify_corruptedData_recoversGracefullyWithoutCrashing() async throws {
        let corruptedData = Data([0xFF, 0xD8, 0x00, 0x12, 0x34]) // Invalid JPEG header
        let result = try await sut.classify(imageData: corruptedData)

        XCTAssertFalse(result.hasFaces)
        XCTAssertEqual(result.category, .toValidate)
    }

    func testCalculateAverageLuminance_pureBlackImage_returnsZeroLuminance() {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var blackPixel: UInt8 = 0
        guard let context = CGContext(
            data: &blackPixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 1,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ), let cgImage = context.makeImage() else {
            XCTFail("Could not create black test image")
            return
        }

        let luminance = FacelessClassificationService.calculateAverageLuminance(for: cgImage)
        XCTAssertEqual(luminance, 0.0, accuracy: 0.01)
    }

    func testCalculateAverageLuminance_pureWhiteImage_returnsHighLuminance() {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var whitePixel: UInt8 = 255
        guard let context = CGContext(
            data: &whitePixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 1,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ), let cgImage = context.makeImage() else {
            XCTFail("Could not create white test image")
            return
        }

        let luminance = FacelessClassificationService.calculateAverageLuminance(for: cgImage)
        XCTAssertEqual(luminance, 1.0, accuracy: 0.01)
    }

    func testClassify_blackImage_isClassifiedAsDeficient() async throws {
        // Generar una imagen negra real (accidental en bolsillo)
        let size = CGSize(width: 64, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            XCTFail("Failed to encode test image")
            return
        }

        let result = try await sut.classify(imageData: data)
        XCTAssertFalse(result.hasFaces)
        XCTAssertEqual(result.category, .deficient)
        XCTAssertLessThan(result.luminanceScore, 0.06)
    }
}
