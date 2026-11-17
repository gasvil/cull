import SwiftUI
import UIKit

/// Vista modal en pantalla completa para inspección detallada de una fotografía (FR-11).
public struct PhotoDetailModalView: View {
    public let candidate: PhotoCandidate
    public let photoLibraryService: PhotoLibraryServiceProtocol
    public let onDismiss: () -> Void

    @State private var fullImage: UIImage? = nil
    @State private var isLoading: Bool = true
    @State private var currentScale: CGFloat = 1.0

    public init(
        candidate: PhotoCandidate,
        photoLibraryService: PhotoLibraryServiceProtocol,
        onDismiss: @escaping () -> Void
    ) {
        self.candidate = candidate
        self.photoLibraryService = photoLibraryService
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let fullImage {
                Image(uiImage: fullImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(currentScale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                currentScale = max(1.0, min(value, 4.0))
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    currentScale = 1.0
                                }
                            }
                    )
            } else if isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            } else {
                VStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    Text("No se pudo cargar la imagen completa")
                        .foregroundColor(.white)
                }
            }

            // Barra superior con botón de cierre y detalles
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formattedDateTime)
                            .font(AppFont.labelMedium)
                            .foregroundColor(.white.opacity(0.8))

                        if let assessment = candidate.assessment {
                            Text("Nitidez: \(Int(assessment.sharpnessScore * 100))% · Calidad: \(Int(assessment.compositeScore * 100))%")
                                .font(AppFont.monoSmall)
                                .foregroundColor(AppColor.keep)
                        }
                    }

                    Spacer()

                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .accessibilityLabel("Cerrar inspección")
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.top, AppTheme.Spacing.large)

                Spacer()
            }
        }
        .task {
            await loadFullResolutionImage()
        }
    }

    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: candidate.asset.creationDate)
    }

    private func loadFullResolutionImage() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await photoLibraryService.fetchImageData(
                for: candidate.id,
                targetSize: CGSize(width: 2048, height: 2048)
            )
            if let image = UIImage(data: data) {
                self.fullImage = image
            }
        } catch {
            // Manejado silenciosamente, mostrando vista de error en modal
        }
    }
}
