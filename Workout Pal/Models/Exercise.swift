import Foundation

struct Exercise: Identifiable, Hashable, Sendable {
    let id: Int
    var uuid: String
    var name: String
    var summary: String
    var category: String
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var equipment: [String]
    var imageURL: URL?
    var license: ContentLicense
    var updatedAt: Date
}

extension Exercise {
    var suggestedLoad: Load {
        let usesBodyweight = equipment.isEmpty || equipment.contains { item in
            let name = item.lowercased()
            return name.contains("bodyweight") || name.contains("none") || name.contains("gym mat")
        }
        return usesBodyweight ? .bodyweight : .kilograms(20)
    }
}

struct ContentLicense: Hashable, Sendable {
    var name: String
    var url: URL?
    var author: String

    var attribution: String {
        author.isEmpty ? name : "\(author), \(name)"
    }
}
