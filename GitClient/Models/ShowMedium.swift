//
//  ShowMedium.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/05/26.
//

import Foundation

struct ShowMedium {
    var commitHashWithLabel: String
    var commitHash: String {
        return commitHashWithLabel.split(separator: " ", maxSplits: 1)[safe: 1].map { String($0)} ?? ""
    }
    var mergeWithLabel: String?
    var mergeParents: (String, String)? {
        guard let mergeWithLabel else {
            return nil
        }
        let splitted = mergeWithLabel.split(separator: " ", maxSplits: 2).map { String($0) }
        guard let parent1 = splitted[safe: 1], let parent2 = splitted[safe: 2] else {
            return nil
        }
        return (parent1, parent2)
    }
    var authorWithLabel: String
    var author: String {
        return authorWithLabel.split(separator: " ", maxSplits: 1)[safe: 1].map { String($0)} ?? ""
    }
    var dateWithLabel: String
    var date: String {
        return dateWithLabel.split(separator: "   ", maxSplits: 1)[safe: 1].map { String($0)} ?? ""
    }
    var commitMessage: String
    var diff: Diff?

    init(raw: String) throws {
        guard !raw.isEmpty else {
            throw GenericError(errorDescription: "raw is empty")
        }
        let spliteDiff = raw.split(separator: "\ndiff", maxSplits: 1)
        guard spliteDiff.count == 2 else {
            let commitInfo = raw
            let commitInfoSplited = commitInfo.split(separator: "\n", maxSplits: 4).map { String($0)}
            commitHashWithLabel = commitInfoSplited[0]
            mergeWithLabel = commitInfoSplited[1]
            authorWithLabel = commitInfoSplited[2]
            dateWithLabel = commitInfoSplited[3]
            commitMessage = commitInfoSplited[4]
            return
        }
        let commitInfo = spliteDiff[0]
        let commitInfoSplited = commitInfo.split(separator: "\n", maxSplits: 3).map { String($0)}
        guard commitInfoSplited.count == 4 else {
            throw GenericError(errorDescription: "Format error for '\n' in ShowMedium")
        }
        commitHashWithLabel = commitInfoSplited[0]
        authorWithLabel = commitInfoSplited[1]
        dateWithLabel = commitInfoSplited[2]
        commitMessage = commitInfoSplited[3]
        diff = try Diff(raw: "diff" + spliteDiff[1])
    }
}
