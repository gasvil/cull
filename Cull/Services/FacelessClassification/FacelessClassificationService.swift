import Foundation
import CoreGraphics
import ImageIO
import Vision

/// Actor responsable de analizar imágenes mediante Vision Framework para detectar ausencia de rostros
/// y clasificar las fotos en Utilitarias, Deficientes o Por Validar (NFR-1, NFR-2, NFR-3).
public actor FacelessClassificationService: FacelessClassificationServiceProtocol {

    public init() {}

    public func classify(imageData: Data) async throws -> FacelessClassificationResult {
        guard !imageData.isEmpty else {
            return FacelessClassificationResult(hasFaces: false, category: .toValidate)
        }

        // Downsampling utilizando CGImageSource para contrapresión de memoria (NFR-3: <= 120MB)
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
            // NFR-5: Resiliencia ante datos corruptos o no decodificables
            return FacelessClassificationResult(hasFaces: false, category: .toValidate)
        }

        return try await processVisionClassification(for: cgImage)
    }

    private func processVisionClassification(for cgImage: CGImage) async throws -> FacelessClassificationResult {
        try await withCheckedThrowingContinuation { continuation in
            autoreleasepool {
                // A. Analizar luminosidad promedio con CoreGraphics (independiente de Vision)
                let luminance = Self.calculateAverageLuminance(for: cgImage)

                // 1. Detección de rostros
                let faceRequest = VNDetectFaceRectanglesRequest()

                // 2. Detección de texto (para Utilitarias: vouchers, comprobantes, documentos)
                let textRequest = VNRecognizeTextRequest()
                textRequest.recognitionLevel = .fast
                textRequest.usesLanguageCorrection = false

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                var faceCount = 0
                var textCount = 0
                var sharpness: Float = 0.5

                do {
                    try handler.perform([faceRequest, textRequest])
                    faceCount = faceRequest.results?.count ?? 0
                    textCount = textRequest.results?.count ?? 0
                } catch {
                    // Si falla el reconocimiento visual base, continuar con valores por defecto
                }

                // 3. Estética / Nitidez (opcional en iOS 18+)
                if #available(iOS 18.0, *) {
                    let aestheticsRequest = VNCalculateImageAestheticsScoresRequest()
                    do {
                        try handler.perform([aestheticsRequest])
                        if let aesResult = aestheticsRequest.results?.first {
                            sharpness = max(0.0, min(1.0, (aesResult.overallScore + 1.0) / 2.0))
                        }
                    } catch {
                        // En simulador o dispositivos sin soporte de Neural Engine, mantener nitidez neutral
                    }
                }

                // B. Comprobar si hay rostros humanos (FR-2)
                if faceCount > 0 {
                    let result = FacelessClassificationResult(
                        hasFaces: true,
                        category: nil,
                        textCount: 0,
                        sharpnessScore: sharpness,
                        luminanceScore: luminance
                    )
                    continuation.resume(returning: result)
                    return
                }

                // C. Clasificación según reglas de negocio (FR-4, FR-5, FR-6)
                let category: FacelessCategory
                if textCount >= 3 {
                    // Vouchers, documentos, capturas con texto predominante
                    category = .utilitarian
                } else if luminance < 0.06 || sharpness < 0.20 {
                    // Casi negra (accidental en bolsillo) o severamente borrosa
                    category = .deficient
                } else {
                    // Tomas nítidas intencionales (paisajes, mascotas, comida)
                    category = .toValidate
                }

                let result = FacelessClassificationResult(
                    hasFaces: false,
                    category: category,
                    textCount: textCount,
                    sharpnessScore: sharpness,
                    luminanceScore: luminance
                )
                continuation.resume(returning: result)
            }
        }
    }

    /// Calcula la luminancia media (0.0 a 1.0) renderizando una muestra reducida en escala de grises.
    public static func calculateAverageLuminance(for image: CGImage) -> Float {
        let width = 16
        let height = 16
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixelData = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return 0.5
        }

        context.interpolationQuality = .low
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let total = pixelData.reduce(0) { $0 + Int($1) }
        let average = Float(total) / Float(pixelData.count)
        return average / 255.0
    }
}
