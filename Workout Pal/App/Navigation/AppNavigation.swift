import Observation

@MainActor
@Observable
final class AppNavigation {
    var selection: AppDestination? = .home
}
