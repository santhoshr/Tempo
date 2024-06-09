//
//  ShowMedium.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/05/26.
//

import Foundation

struct ShowMedium {
    var commitHash: String
    var author: String
    var date: String
    var commitMessage: String
    var diff: Diff

    init(raw: String) throws {
        let spliteDiff = raw.split(separator: "\ndiff", maxSplits: 1)
        guard spliteDiff.count == 2 else {
            throw GenericError(errorDescription: "Format error")
        }
        let commitInfo = spliteDiff[0]
        let commitInfoSplited = commitInfo.split(separator: "\n", maxSplits: 3).map { String($0)}
        guard commitInfoSplited.count == 4 else {
            throw GenericError(errorDescription: "Format error")
        }
        commitHash = commitInfoSplited[0]
        author = commitInfoSplited[1]
        date = commitInfoSplited[2]
        commitMessage = commitInfoSplited[3]
        diff = try Diff(raw: "diff" + spliteDiff[1])
    }
}
