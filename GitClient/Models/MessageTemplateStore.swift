//
//  MessageTemplateStore.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/04.
//

import Foundation
import Collections

struct MessageTemplateStore {
    static let defaults = UserDefaults.standard

    static func messageTemplates() throws -> OrderedSet<MessageTemplate> {
        guard let data = defaults.data(forKey: .messageTemplate) else
             {
            throw GenericError(errorDescription: "The data object associated with the specified key, or nil if the key does not exist or its value is not a data object.")
        }
        let decoder = JSONDecoder()
        return try decoder.decode(OrderedSet<MessageTemplate>.self, from: data)
    }

    static func save(_ messageTemplates: OrderedSet<MessageTemplate>) throws {
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(messageTemplates)
        defaults.set(encoded, forKey: .messageTemplate)
    }
}
