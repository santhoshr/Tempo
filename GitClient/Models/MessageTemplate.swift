//
//  MessageTemplate.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/04.
//

import Foundation

struct MessageTemplate: Hashable, Codable {
    var message: String

    init?(message: String) {
        guard !message.isEmpty else { return nil }
        self.message = message
    }
}
