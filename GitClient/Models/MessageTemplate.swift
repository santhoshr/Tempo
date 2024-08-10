//
//  MessageTemplate.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/04.
//

import Foundation

struct MessageTemplate: Hashable, Codable, Identifiable {
    var id: String { message }
    var message: String
}
