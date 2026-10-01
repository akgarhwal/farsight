import Foundation

struct Card: Decodable {
    let text: String
    let author: String?
    var category = ""

    private enum CodingKeys: String, CodingKey { case text, author }
}

private struct CardFile: Decodable {
    let category: String
    let items: [Card]
}

/// Quotes and learning tips bundled as Resources/Tips/*.json, one file per category.
enum CardDeck {
    static let all: [Card] = {
        let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Tips") ?? []
        return urls.flatMap { url -> [Card] in
            guard let data = try? Data(contentsOf: url),
                  let file = try? JSONDecoder().decode(CardFile.self, from: data) else {
                NSLog("Farsight: skipping unreadable tips file \(url.lastPathComponent)")
                return []
            }
            return file.items.map { card in
                var card = card
                card.category = file.category
                return card
            }
        }
    }()

    private static var lastIndex: Int?

    /// A random card, never the same one twice in a row.
    static func random() -> Card? {
        guard !all.isEmpty else { return nil }
        var index = Int.random(in: 0..<all.count)
        if all.count > 1, index == lastIndex {
            index = (index + 1) % all.count
        }
        lastIndex = index
        return all[index]
    }
}
