import XCTest
import CoreGraphics
import ImageIO
@testable import Cull

final class ImageQualityEvaluatorTests: XCTestCase {
    private var sut: VisionQualityEvaluator!

    override func setUp() {
        super.setUp()
        sut = VisionQualityEvaluator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    private func createTestImageData(width: Int = 100, height: Int = 100, color: CGColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return Data()
        }

        context.setFillColor(color)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage() else { return Data() }
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData as CFMutableData, "public.jpeg" as CFString, 1, nil) else {
            return Data()
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return mutableData as Data
    }

    func testEvaluateQuality_calculatesSharpnessScoreNormalized() async throws {
        let imageData = createTestImageData()
        XCTAssertFalse(imageData.isEmpty)

        let assessment = try await sut.evaluateQuality(for: imageData)

        XCTAssertGreaterThanOrEqual(assessment.sharpnessScore, 0.0)
        XCTAssertLessThanOrEqual(assessment.sharpnessScore, 1.0)
        XCTAssertGreaterThanOrEqual(assessment.compositeScore, 0.0)
        XCTAssertLessThanOrEqual(assessment.compositeScore, 1.0)
    }

    func testEvaluateQuality_calculatesCompositeScoreWithoutFaces_usingSharpnessAndExposure() async throws {
        // An image of a solid color has no faces (EC-5)
        let imageData = createTestImageData()

        let assessment = try await sut.evaluateQuality(for: imageData)

        XCTAssertNil(assessment.faceAssessment)
        // With no faces: composite = sharpness * 0.70 + exposure * 0.30
        let expected = (assessment.sharpnessScore * 0.70) + (assessment.exposureScore * 0.30)
        XCTAssertEqual(assessment.compositeScore, expected, accuracy: 0.01)
    }

    func testEvaluateQuality_penalizesClosedEyesInFaceAssessment() {
        // Pure calculation test for the composite score algorithm
        let openEyesFace = FaceAssessment(faceCount: 1, allEyesOpen: true, openEyesConfidence: 0.95)
        let closedEyesFace = FaceAssessment(faceCount: 1, allEyesOpen: false, openEyesConfidence: 0.10)

        let openEyesComposite = VisionQualityEvaluator.calculateCompositeScore(
            sharpness: 0.9,
            exposure: 0.8,
            faceAssessment: openEyesFace
        )

        let closedEyesComposite = VisionQualityEvaluator.calculateCompositeScore(
            sharpness: 0.9,
            exposure: 0.8,
            faceAssessment: closedEyesFace
        )

        XCTAssertGreaterThan(openEyesComposite, closedEyesComposite)
    }

    func testEvaluateQuality_handlesCorruptedImageDataGracefully_withoutCrashing() async throws {
        let corruptedData = Data([0xFF, 0xD8, 0x00, 0x11, 0x22, 0x33]) // Invalid JPEG header

        // NFR-5: Graceful degradation, returns baseline assessment without throwing unhandled crash
        let assessment = try await sut.evaluateQuality(for: corruptedData)

        XCTAssertEqual(assessment.sharpnessScore, 0.0)
        XCTAssertEqual(assessment.compositeScore, 0.0)
        XCTAssertNil(assessment.faceAssessment)
    }
}
