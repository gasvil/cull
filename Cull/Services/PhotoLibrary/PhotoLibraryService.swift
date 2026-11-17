import Foundation
import Photos
import UIKit

/// Implementación concreta de `PhotoLibraryServiceProtocol` usando PhotoKit.
public final class PhotoLibraryService: PhotoLibraryServiceProtocol, @unchecked Sendable {

    public init() {}

    public func requestAuthorization() async -> Bool {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch currentStatus {
        case .authorized, .limited:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return status == .authorized || status == .limited
        @unknown default:
            return false
        }
    }

    public func fetchRecentAssets(limit: Int = 100) async throws -> [PhotoAsset] {
        try await fetchAssets(startDate: nil, endDate: nil, limit: limit)
    }

    public func fetchAssets(startDate: Date?, endDate: Date?, limit: Int = 200) async throws -> [PhotoAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = limit
        options.includeHiddenAssets = false

        if let startDate, let endDate {
            options.predicate = NSPredicate(
                format: "creationDate >= %@ AND creationDate <= %@",
                startDate as NSDate,
                endDate as NSDate
            )
        } else if let startDate {
            options.predicate = NSPredicate(
                format: "creationDate >= %@",
                startDate as NSDate
            )
        } else if let endDate {
            options.predicate = NSPredicate(
                format: "creationDate <= %@",
                endDate as NSDate
            )
        }

        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PhotoAsset] = []

        fetchResult.enumerateObjects { phAsset, _, _ in
            let byteSize = Self.estimateByteSize(for: phAsset)
            let asset = PhotoAsset(
                id: phAsset.localIdentifier,
                creationDate: phAsset.creationDate ?? Date(),
                pixelWidth: phAsset.pixelWidth,
                pixelHeight: phAsset.pixelHeight,
                byteSize: byteSize,
                isFavorite: phAsset.isFavorite,
                burstIdentifier: phAsset.burstIdentifier,
                representsBurst: phAsset.representsBurst
            )
            assets.append(asset)
        }

        return assets
    }

    public func fetchAssetCount(startDate: Date?, endDate: Date?) async throws -> Int {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false

        if let startDate, let endDate {
            options.predicate = NSPredicate(
                format: "creationDate >= %@ AND creationDate <= %@",
                startDate as NSDate,
                endDate as NSDate
            )
        } else if let startDate {
            options.predicate = NSPredicate(
                format: "creationDate >= %@",
                startDate as NSDate
            )
        } else if let endDate {
            options.predicate = NSPredicate(
                format: "creationDate <= %@",
                endDate as NSDate
            )
        }

        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        return fetchResult.count
    }

    public func fetchImageData(for assetId: String, targetSize: CGSize) async throws -> Data {
        let options = PHFetchOptions()
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: options)

        guard let phAsset = fetchResult.firstObject else {
            throw AppError.resourceNotFound(identifier: assetId)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let imageOptions = PHImageRequestOptions()
            imageOptions.deliveryMode = .highQualityFormat
            imageOptions.isNetworkAccessAllowed = true
            imageOptions.isSynchronous = false

            PHImageManager.default().requestImageDataAndOrientation(for: phAsset, options: imageOptions) { data, _, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: AppError.operationFailed(description: error.localizedDescription))
                    return
                }

                if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: AppError.resourceNotFound(identifier: assetId))
                }
            }
        }
    }

    public func deleteAssets(withIDs ids: [String]) async throws -> Bool {
        guard !ids.isEmpty else { return true }

        let options = PHFetchOptions()
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: options)
        guard fetchResult.count > 0 else { return true }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(fetchResult)
            }
            return true
        } catch {
            let nsError = error as NSError
            // Si el usuario cancela en el diálogo nativo (código 3072 o domain PhotoKit / CocoaError)
            if nsError.code == 3072 || nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError {
                // EC-6: No es un fallo crítico, simplemente el usuario canceló
                return false
            }
            throw AppError.operationFailed(description: error.localizedDescription)
        }
    }

    private static func estimateByteSize(for asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        if let primaryResource = resources.first(where: { $0.type == .photo || $0.type == .fullSizePhoto }),
           let fileSize = primaryResource.value(forKey: "fileSize") as? Int64, fileSize > 0 {
            return fileSize
        }
        // Estimación heurística de JPEG (aprox. 0.4 bytes por pixel) si el recurso no expone fileSize
        return Int64(Double(asset.pixelWidth * asset.pixelHeight) * 0.4)
    }
}
