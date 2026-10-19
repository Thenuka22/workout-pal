import Foundation

enum HTMLText {
    static func plainText(from html: String) -> String {
        var text = html
        for tag in ["</p>", "<br>", "<br/>", "<br />", "</li>", "</h1>", "</h2>", "</h3>"] {
            text = text.replacingOccurrences(of: tag, with: "\n", options: .caseInsensitive)
        }
        text = text.replacingOccurrences(of: "<li>", with: "- ", options: .caseInsensitive)

        var stripped = ""
        var insideTag = false
        for character in text {
            if character == "<" {
                insideTag = true
            } else if character == ">" {
                insideTag = false
            } else if !insideTag {
                stripped.append(character)
            }
        }

        let entities = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
        ]
        for (entity, value) in entities {
            stripped = stripped.replacingOccurrences(of: entity, with: value)
        }

        let lines = stripped
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\r" }).joined(separator: " ") }
            .filter { !$0.isEmpty }
        return lines.joined(separator: "\n")
    }
}
