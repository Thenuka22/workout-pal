import Foundation

struct WgerClient: Sendable {
    private let session: URLSession
    private let baseURL = URL(string: "https://wger.de/api/v2/")

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchExercisePage(limit: Int, offset: Int) async throws -> ExercisePageDTO {
        guard let baseURL,
              var components = URLComponents(url: baseURL.appending(path: "exerciseinfo/"), resolvingAgainstBaseURL: false)
        else {
            throw WgerClientError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        guard let url = components.url else {
            throw WgerClientError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw WgerClientError.badResponse(0)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw WgerClientError.badResponse(http.statusCode)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ExercisePageDTO.self, from: data)
    }
}

enum WgerClientError: Error, LocalizedError {
    case invalidURL
    case badResponse(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The exercise service address is invalid."
        case .badResponse(let status):
            "The exercise service answered with status \(status)."
        }
    }
}

struct ExercisePageDTO: Decodable, Sendable {
    let count: Int
    let next: String?
    let results: [ExerciseInfoDTO]
}

struct ExerciseInfoDTO: Decodable, Sendable {
    let id: Int
    let uuid: String?
    let category: NamedDTO?
    let muscles: [MuscleDTO]?
    let musclesSecondary: [MuscleDTO]?
    let equipment: [NamedDTO]?
    let license: LicenseDTO?
    let licenseAuthor: String?
    let images: [ImageDTO]?
    let translations: [TranslationDTO]?
}

struct NamedDTO: Decodable, Sendable {
    let id: Int
    let name: String
}

struct MuscleDTO: Decodable, Sendable {
    let id: Int
    let name: String
    let nameEn: String?
}

struct LicenseDTO: Decodable, Sendable {
    let shortName: String?
    let fullName: String?
    let url: String?
}

struct ImageDTO: Decodable, Sendable {
    let image: String
    let isMain: Bool?
}

struct TranslationDTO: Decodable, Sendable {
    let name: String
    let description: String?
    let language: Int
}
