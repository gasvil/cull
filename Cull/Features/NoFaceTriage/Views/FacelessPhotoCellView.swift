import SwiftUI

/// Celda compacta para una foto en la cuadrícula de 3 columnas de depuración sin rostro (FR-8 a FR-13).
public struct FacelessPhotoCellView: View {
    public let candidate: FacelessPhotoCandidate
    public let photoLibraryService: PhotoLibraryServiceProtocol
    public let onToggle: () -> Void
    public let onPreview: () -> Void

    public init(
        candidate: FacelessPhotoCandidate,
        photoLibraryService: PhotoLibraryServiceProtocol,
        onToggle: @escaping () -> Void,
        onPreview: @escaping () -> Void
    ) {
        self.candidate = candidate
        self.photoLibraryService = photoLibraryService
        self.onToggle = onToggle
        self.onPreview = onPreview
    }

    public var body: some View {
        Button {
            onToggle()
        } label: {
            ZStack(alignment: .bottom) {
                // Miniatura con tamaño optimizado y relación de aspecto consistente
                PhotoThumbnailView(
                    assetId: candidate.id,
                    targetSize: CGSize(width: 300, height: 350),
                    cornerRadius: AppTheme.CornerRadius.small,
                    photoLibraryService: photoLibraryService
                )
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .strokeBorder(candidate.isSelected ? AppColor.cull : AppColor.outlineVariant.opacity(0.6), lineWidth: candidate.isSelected ? 2 : 1)
                )

                // Etiqueta semántica inferior con categoría y peso (FR-12)
                Text("\(candidate.category.singularTitle) · \(candidate.formattedByteSize)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.65))
                    .clipShape(Capsule())
                    .padding(.bottom, 6)
                    .padding(.horizontal, 4)

                // Indicador de selección en la esquina superior derecha (FR-10)
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            if candidate.isSelected {
                                Circle()
                                    .fill(AppColor.cull)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            } else {
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
                                    .background(Circle().fill(Color.black.opacity(0.25)))
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(6)
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onEnded { _ in
                    onPreview()
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(candidate.category.singularTitle), \(candidate.formattedByteSize), \(candidate.isSelected ? "Marcada para eliminar" : "No marcada")")
        .accessibilityHint("Toca para alternar selección o mantén presionado para ver en grande")
    }
}
