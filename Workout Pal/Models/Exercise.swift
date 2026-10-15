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

struct ContentLicense: Hashable, Sendable {
    var name: String
    var url: URL?
    var author: String

    var attribution: String {
        author.isEmpty ? name : "\(author), \(name)"
    }
}
