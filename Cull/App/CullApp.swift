import SwiftUI

@main
struct CullApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            @Bindable var router = environment.router

            NavigationStack(path: $router.path) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .home:
                            HomeView()
                        case .modeSelection(let start, let end, let desc):
                            ModeSelectionView(
                                viewModel: ModeSelectionViewModel(
                                    startDate: start,
                                    endDate: end,
                                    periodDescription: desc
                                )
                            )
                        case .burstTriage:
                            BurstTriageView(viewModel: environment.makeBurstTriageViewModel())
                        case .noFaceTriage:
                            NoFaceTriageView(viewModel: environment.makeNoFaceTriageViewModel())
                        case .detail(let title):
                            DetailPlaceholderView(title: title)
                        }
                    }
            }
            .environment(environment)
            .environment(environment.router)
        }
    }
}

/// Vista placeholder para ilustrar la navegación tipada.
private struct DetailPlaceholderView: View {
    let title: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            Text(title)
                .font(.title2)
                .bold()
            Text("Navegación desacoplada y tipada funcionando.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Detalle")
    }
}
