enum Load: Hashable, Sendable {
    case bodyweight
    case kilograms(Double)

    var isBodyweight: Bool {
        if case .bodyweight = self {
            return true
        }
        return false
    }

    var kilograms: Double? {
        if case .kilograms(let value) = self {
            return value
        }
        return nil
    }
}
