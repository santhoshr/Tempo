//
//  CommitDetail.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/08.
//

import Foundation
import CryptoKit

struct CommitDetail: Hashable {
    var commit: Commit
    var diff: Diff
}
