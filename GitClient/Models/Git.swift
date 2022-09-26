//
//  Git.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import Foundation

protocol Git {
    associatedtype OutputModel
    var arguments: [String] { get set}
    var directory: URL { get set }
    func parse(for stdOut: String) -> OutputModel
}
