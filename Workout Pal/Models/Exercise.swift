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
        let weights = ["barbell", "sz-bar", "dumbbell", "kettlebell", "cable"]
        let usesWeights = equipment.contains { item in
            weights.contains { item.lowercased().contains($0) }
        }
        return usesWeights ? .kilograms(20) : .bodyweight
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
