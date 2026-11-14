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
                List(items) { item in
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
