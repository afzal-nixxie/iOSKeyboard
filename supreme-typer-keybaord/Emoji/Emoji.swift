//
//  Emoji.swift
//  s-type
//

struct Emoji: Codable {

    let name: String
    let unified: String
    let shortName: String
    let shortNames: [String]
    let category: String
    let subcategory: String?
    let sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case unified
        case shortName = "short_name"
        case shortNames = "short_names"
        case category
        case subcategory
        case sortOrder = "sort_order"
    }

    /// Converts "0023-FE0F-20E3" → "#️⃣"
    var symbol: String {
        let scalars = unified
            .split(separator: "-")
            .compactMap { UInt32($0, radix: 16) }
            .compactMap { UnicodeScalar($0) }

        return String(String.UnicodeScalarView(scalars))
    }

    /// New property for Keyboard code compatibility
    var text: String {
        return symbol
    }
}
