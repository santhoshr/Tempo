//
//  GenericError.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/24.
//

import Foundation

struct GenericError: Error, LocalizedError {
    var errorDescription: String?

    init(errorDescription: String) {
        self.errorDescription = errorDescription
    }
}
