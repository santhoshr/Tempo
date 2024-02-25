//
//  Git.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import Foundation

protocol Git {
    associatedtype OutputModel
    var arguments: [String] { get }
    var directory: URL { get set }
    func parse(for standardOutput: String) throws -> OutputModel
}
