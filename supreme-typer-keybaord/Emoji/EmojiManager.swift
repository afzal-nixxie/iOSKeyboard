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
    private let recentsKey = "com.stype.recentEmojis"

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
            
            // Extract categories and ensure "Recents" is always first
            let distinctCategories = Array(Set(decoded.map { $0.category })).sorted()
            categories = ["Recents"] + distinctCategories

            print("✅ Loaded \(emojis.count) emojis")
            print("✅ Categories:", categories)

        } catch {
            print("❌ Failed to load emojis:", error)
        }
    }

    // MARK: - Public Helpers
    func emojis(for category: String) -> [Emoji] {
        if category == "Recents" {
            return recentEmojis()
        }
        return emojis.filter { $0.category == category }
    }

    func search(_ text: String) -> [Emoji] {
        let lower = text.lowercased()
        return emojis.filter {
            $0.name.lowercased().contains(lower) ||
            $0.shortName.lowercased().contains(lower) ||
            $0.shortNames.contains(where: { $0.lowercased().contains(lower) })
        }
    }

    // MARK: - Recents Logic
    func addToRecents(_ emoji: Emoji) {
        var recents = recentEmojis()
        
        // Remove if exists to move to top
        if let index = recents.firstIndex(where: { $0.unified == emoji.unified }) {
            recents.remove(at: index)
        }
        
        recents.insert(emoji, at: 0)
        
        // Limit to 20
        if recents.count > 20 {
            recents = Array(recents.prefix(20))
        }
        
        saveRecents(recents)
    }

    private func recentEmojis() -> [Emoji] {
        guard let data = UserDefaults.standard.data(forKey: recentsKey) else { return [] }
        do {
            return try JSONDecoder().decode([Emoji].self, from: data)
        } catch {
            return []
        }
    }

    private func saveRecents(_ recents: [Emoji]) {
        do {
            let data = try JSONEncoder().encode(recents)
            UserDefaults.standard.set(data, forKey: recentsKey)
        } catch {
            print("Failed to save recents")
        }
    }
}
