import SwiftUI

/// Vista principal de la aplicación.
/// Sigue el principio de responsabilidad única (SRP), delegando la lógica al `HomeViewModel`.
public struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @Environment(AppRouter.self) private var router

    public init() {}

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("Cargando...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let items):
                List {
                    Section {
                        Button {
                            router.navigate(to: .burstTriage)
                        } label: {
                            HStack(spacing: AppTheme.Spacing.medium) {
                                Image(systemName: "square.stack.3d.down.right.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                                    Text("Curación de Ráfagas")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Detecta la mejor toma y agrupa duplicadas")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, AppTheme.Spacing.xxSmall)
                        }

                        Button {
                            router.navigate(to: .noFaceTriage)
                        } label: {
                            HStack(spacing: AppTheme.Spacing.medium) {
                                Image(systemName: "person.slash.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                                    Text("Fotos Sin Rostros")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Vouchers, documentos, capturas y fotos borrosas")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, AppTheme.Spacing.xxSmall)
                        }
                    } header: {
                        Text("Acciones Rápidas")
                    }

                    Section {
                        ForEach(items) { item in
                            Button {
                                router.navigate(to: .detail(title: item.title))
                            } label: {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxSmall) {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(item.subtitle)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, AppTheme.Spacing.xxSmall)
                            }
                        }
                    } header: {
                        Text("Módulos")
                    }
                }
            case .error(let message):
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .navigationTitle("Cull")
        .task {
            viewModel.loadInitialData()
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(AppRouter())
    }
}
