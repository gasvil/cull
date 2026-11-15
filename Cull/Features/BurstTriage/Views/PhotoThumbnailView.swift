import SwiftUI
import UIKit

/// Componente que carga y renderiza de forma asíncrona la miniatura de un activo fotográfico.
public struct PhotoThumbnailView: View {
    public let assetId: String
    public let targetSize: CGSize
    public let photoLibraryService: PhotoLibraryServiceProtocol

    @State private var image: UIImage? = nil
    @State private var isLoading: Bool = false

    public init(
        assetId: String,
        targetSize: CGSize = CGSize(width: 200, height: 260),
        photoLibraryService: PhotoLibraryServiceProtocol
    ) {
        self.assetId = assetId
        self.targetSize = targetSize
        self.photoLibraryService = photoLibraryService
    }

    public var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 130)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 100, height: 130)
                    .overlay {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
        .task(id: assetId) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard image == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await photoLibraryService.fetchImageData(for: assetId, targetSize: targetSize)
            if let uiImage = UIImage(data: data) {
                self.image = uiImage
            }
        } catch {
            // Si falla la decodificación, se mantiene el placeholder sin crashear
        }
    }
}
