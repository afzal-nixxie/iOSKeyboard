//
//  EmojiManager.swift
//  s-type
//
//  Created by Afzal on 2/9/26.
//

import Foundation

final class EmojiManager {

    static let shared = EmojiManager()

    private(set) var emojis: [Emoji] = []
    private(set) var categories: [String] = []

    private init() {
        loadEmojis()
    }

    // MARK: - Load JSON
    private func loadEmojis() {
        guard let url = Bundle.main.url(forResource: "emojis", withExtension: "json") else {
            print("❌ emojis.json not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Emoji].self, from: data)
            emojis = decoded
            categories = Array(Set(decoded.map { $0.category })).sorted()

            print("✅ Loaded \(emojis.count) emojis")
            print("✅ Categories:", categories)

        } catch {
            print("❌ Failed to load emojis:", error)
        }
    }

    // MARK: - Public Helpers (used later)
    func emojis(for category: String) -> [Emoji] {
        emojis.filter { $0.category == category }
    }

    func search(_ text: String) -> [Emoji] {
        let lower = text.lowercased()
        return emojis.filter {
            $0.name.lowercased().contains(lower) ||
            $0.shortName.lowercased().contains(lower) ||
            $0.shortNames.contains(where: { $0.lowercased().contains(lower) })
        }
    }

}
