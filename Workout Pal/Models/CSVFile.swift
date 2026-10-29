import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// A CSV file that only exists in memory until it is shared.
struct CSVFile: Transferable, Hashable, Sendable {
    let fileName: String
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { file in
            Data(file.text.utf8)
        }
        .suggestedFileName { $0.fileName }
    }
}
