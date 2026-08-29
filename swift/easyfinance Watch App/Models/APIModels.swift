import Foundation

nonisolated struct AgentRequest: Encodable, Sendable {
    let userID: String
    let query: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case query
    }
}

nonisolated struct SpendingsRequest: Encodable, Sendable {
    let userID: String
    let limit: Int

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case limit
    }
}

nonisolated struct AgentResponse: Decodable, Sendable {
    let response: String
}

nonisolated struct SpendingsResponse: Decodable, Sendable {
    let spendings: [Spending]
}

nonisolated enum SpendingCategory: String, Codable, CaseIterable, Sendable {
    case food
    case transport
    case shopping
    case entertainment
    case tech
    case health
    case travel
    case education
    case other

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = SpendingCategory(rawValue: value.lowercased()) ?? .other
    }

    var displayName: String {
        switch self {
        case .food: "Comida"
        case .transport: "Transporte"
        case .shopping: "Compras"
        case .entertainment: "Entretenimiento"
        case .tech: "Tecnología"
        case .health: "Salud"
        case .travel: "Viajes"
        case .education: "Educación"
        case .other: "Otros"
        }
    }

    var symbolName: String {
        switch self {
        case .food: "fork.knife"
        case .transport: "bus.fill"
        case .shopping: "bag.fill"
        case .entertainment: "ticket.fill"
        case .tech: "desktopcomputer"
        case .health: "cross.case.fill"
        case .travel: "airplane"
        case .education: "book.fill"
        case .other: "square.grid.2x2.fill"
        }
    }
}

nonisolated struct Spending: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let category: SpendingCategory
    let subcategory: String?
    let description: String?
    let amount: Double
    let currency: String
    let quantity: Int
    let paymentMethod: String?
    let isRecurring: Bool
    let spendingDate: String

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case subcategory
        case description
        case amount
        case currency
        case quantity
        case paymentMethod = "payment_method"
        case isRecurring = "is_recurring"
        case spendingDate = "date"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let stringID = try? container.decode(String.self, forKey: .id) {
            id = stringID
        } else if let integerID = try? container.decode(Int.self, forKey: .id) {
            id = String(integerID)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .id,
                in: container,
                debugDescription: "Expected a string or integer spending id."
            )
        }

        category = try container.decode(SpendingCategory.self, forKey: .category)
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory)
        description = try container.decodeIfPresent(String.self, forKey: .description)

        if let numericAmount = try? container.decode(Double.self, forKey: .amount) {
            amount = numericAmount
        } else {
            let stringAmount = try container.decode(String.self, forKey: .amount)
            guard let parsedAmount = Double(stringAmount) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .amount,
                    in: container,
                    debugDescription: "Expected a numeric amount."
                )
            }
            amount = parsedAmount
        }

        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "PEN"
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        paymentMethod = try container.decodeIfPresent(String.self, forKey: .paymentMethod)
        isRecurring = try container.decodeIfPresent(Bool.self, forKey: .isRecurring) ?? false
        spendingDate = try container.decodeIfPresent(String.self, forKey: .spendingDate) ?? ""
    }

    var title: String {
        if let description = description?.trimmedNonEmpty {
            return description
        }
        if let subcategory = subcategory?.trimmedNonEmpty {
            return subcategory.capitalized
        }
        return category.displayName
    }

    var categoryDetail: String {
        guard let subcategory = subcategory?.trimmedNonEmpty else {
            return category.displayName
        }
        return "\(category.displayName) · \(subcategory.capitalized)"
    }

    var formattedAmount: String {
        let symbol = currency.uppercased() == "USD" ? "$" : "S/"
        return String(format: "%@ %.2f", symbol, amount)
    }

    var dateValue: Date? {
        let components = spendingDate.prefix(10).split(separator: "-")
        guard components.count == 3,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]) else {
            return nil
        }

        return Calendar.current.date(
            from: DateComponents(year: year, month: month, day: day)
        )
    }

    var isToday: Bool {
        guard let dateValue else { return false }
        return Calendar.current.isDateInToday(dateValue)
    }
}

private nonisolated extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
