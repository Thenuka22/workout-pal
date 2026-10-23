enum HealthExportStatus: String, Sendable {
    case notExported
    case exported
    case failed

    var title: String {
        switch self {
        case .notExported: "Not saved to Apple Health"
        case .exported: "Saved to Apple Health"
        case .failed: "Could not save to Apple Health"
        }
    }
}
