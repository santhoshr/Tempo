//
//  MessageTemplateStore.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/04.
//

import Foundation

struct MessageTemplateStore {
    static let defaults = UserDefaults.standard

    static func messageTemplates() throws -> [MessageTemplate] {
        guard let data = defaults.data(forKey: .folder) else
             {
            throw GenericError(errorDescription: "The data object associated with the specified key, or nil if the key does not exist or its value is not a data object.")
        }
        let decoder = JSONDecoder()
        return try decoder.decode([MessageTemplate].self, from: data)
    }

    static func save(_ messageTemplate: [MessageTemplate]) throws {
        let prefix = Array(messageTemplate.prefix(100))
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(prefix)
        defaults.set(encoded, forKey: .messageTemplate)
    }
}
