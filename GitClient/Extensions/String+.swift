//
//  String+.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/26.
//

import Foundation

extension String {
    static let formatSeparator = "{separator-44cd166895ac93832525}"
    static let componentSeparator = "{component-separator-44cd166895ac93832525}"

    var initial: String {
        self.components(separatedBy: .whitespaces).map { $0.prefix(1).uppercased() }.joined()
    }
}
