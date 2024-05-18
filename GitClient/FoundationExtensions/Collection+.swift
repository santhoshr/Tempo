//
//  Collection+.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/05/11.
//

import Foundation

public extension Collection {
    subscript(safe index: Index) -> Element? {
        startIndex <= index && index < endIndex ? self[index] : nil
    }
}
