import Foundation
import CoreGraphics
import ImageIO
import Vision

/// Actor responsable de la evaluación de calidad de imagen mediante Vision Framework.
/// Diseñado como un `actor` para garantizar ejecución fuera del hilo principal y contrapresión de memoria (NFR-2, NFR-3).
public actor VisionQualityEvaluator: ImageQualityEvaluatorProtocol {

    public init() {}

    public func evaluateQuality(for imageData: Data) async throws -> QualityAssessment {
        guard !imageData.isEmpty else {
            return QualityAssessment(sharpnessScore: 0.0, exposureScore: 0.0, compositeScore: 0.0)
        }

        // Downsampling utilizando CGImageSource para cumplir NFR-3 (RAM <= 120MB sobre baseline)
        let downsampledCGImage = autoreleasepool { () -> CGImage? in
            let options: [CFString: Any] = [
                kCGImageSourceShouldCache: false
            ]
            guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, options as CFDictionary) else {
                return nil
            }

            let thumbnailOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1024
            ]

            return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailOptions as CFDictionary)
        }

        guard let cgImage = downsampledCGImage else {
            // NFR-5: Si los datos están corruptos o no se decodifican, retornar evaluación nula sin fallar
            return QualityAssessment(sharpnessScore: 0.0, exposureScore: 0.0, compositeScore: 0.0)
        }

        return try await processVisionRequests(for: cgImage)
    }

    private func processVisionRequests(for cgImage: CGImage) async throws -> QualityAssessment {
        try await withCheckedThrowingContinuation { continuation in
            autoreleasepool {
                var sharpness: Float = 0.5
                var exposure: Float = 0.5
                var faceAssessment: FaceAssessment?

                var requests: [VNRequest] = []

                // 1. Detección de calidad de rostros (iOS 13+)
                let faceQualityRequest = VNDetectFaceCaptureQualityRequest()
                requests.append(faceQualityRequest)

                // 2. Cálculo de estética/nitidez si está en iOS 18+, o fallback para iOS 17
                if #available(iOS 18.0, *) {
                    let aestheticsRequest = VNCalculateImageAestheticsScoresRequest()
                    requests.append(aestheticsRequest)
                }

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                do {
                    try handler.perform(requests)

                    if #available(iOS 18.0, *) {
                        if let aestheticsResult = requests.compactMap({ $0 as? VNCalculateImageAestheticsScoresRequest }).first?.results?.first {
                            sharpness = max(0.0, min(1.0, (aestheticsResult.overallScore + 1.0) / 2.0))
                        }
                    }

                    // Extraer resultado de rostros
                    if let faceResults = faceQualityRequest.results as? [VNFaceObservation], !faceResults.isEmpty {
                        let count = faceResults.count
                        var totalQuality: Float = 0.0
                        var allOpen = true

                        for face in faceResults {
                            let quality = face.faceCaptureQuality ?? 0.5
                            totalQuality += quality
                            // Si la calidad facial es baja (< 0.25), se asume ojos cerrados/parpadeo o desenfoque
                            if quality < 0.25 {
                                allOpen = false
                            }
                        }

                        let avgQuality = totalQuality / Float(count)
                        faceAssessment = FaceAssessment(
                            faceCount: count,
                            allEyesOpen: allOpen,
                            openEyesConfidence: avgQuality
                        )
                    }

                    let composite = Self.calculateCompositeScore(
                        sharpness: sharpness,
                        exposure: exposure,
                        faceAssessment: faceAssessment
                    )

                    let assessment = QualityAssessment(
                        sharpnessScore: sharpness,
                        exposureScore: exposure,
                        faceAssessment: faceAssessment,
                        compositeScore: composite
                    )
                    continuation.resume(returning: assessment)
                } catch {
                    // Si ocurre un error interno en Vision, degradar a evaluación neutral (P4 / NFR-5)
                    let fallback = QualityAssessment(
                        sharpnessScore: 0.5,
                        exposureScore: 0.5,
                        compositeScore: 0.5
                    )
                    continuation.resume(returning: fallback)
                }
            }
        }
    }

    /// Calcula la ponderación compuesta según las reglas de negocio (Assumption 2, FR-4).
    public static func calculateCompositeScore(
        sharpness: Float,
        exposure: Float,
        faceAssessment: FaceAssessment?
    ) -> Float {
        if let faces = faceAssessment {
            // Con rostros: 40% nitidez, 40% ojos abiertos/expresión, 20% exposición
            let eyesFactor: Float = faces.allEyesOpen ? faces.openEyesConfidence : (faces.openEyesConfidence * 0.2)
            let rawScore = (sharpness * 0.40) + (eyesFactor * 0.40) + (exposure * 0.20)
            return max(0.0, min(1.0, rawScore))
        } else {
            // Sin rostros: 70% nitidez, 30% exposición
            let rawScore = (sharpness * 0.70) + (exposure * 0.30)
            return max(0.0, min(1.0, rawScore))
        }
    }
}
