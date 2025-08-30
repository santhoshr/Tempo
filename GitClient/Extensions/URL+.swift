//
//  URL+.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/26.
//

import Foundation

extension URL {
    static var testFixture: URL? {
        guard let srcroot = ProcessInfo.processInfo.environment["SRCROOT"] else { return nil }
        return URL(fileURLWithPath: srcroot).appending(path: "TestFixtures").appending(path: "SyntaxHighlight")
    }

}
