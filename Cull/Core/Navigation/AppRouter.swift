import SwiftUI

/// Enrutador centralizado que administra la pila de navegación de SwiftUI.
/// Utiliza `@Observable` y `@MainActor` para garantizar actualizaciones seguras en el hilo principal.
@Observable
@MainActor
public final class AppRouter {
    public var path = NavigationPath()

    public init() {}

    public func navigate(to route: AppRoute) {
        path.append(route)
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func navigateBack() {
        pop()
    }

    public func popToRoot() {
        path = NavigationPath()
    }
}
