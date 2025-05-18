//
//  MergeCommitContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/13.
//

import SwiftUI

struct MergeCommitContentView: View {
    var mergeCommit: Commit
    var directoryURL: URL
    @State private var commits: [Commit] = []
    @State private var filesChanged: [ExpandableModel<FileDiff>] = []
    @State private var error: Error?
    @State private var tab = 0
    private var authorEmails: [String] {
        commits.map { $0.authorEmail }
            .reduce(into: []) { result, item in
                if !result.contains(item) {
                    result.append(item)
                }
            }
    }
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DiffTabView(tab: $tab)
                .padding(.vertical)
            if tab == 0 {
                DiffCommitListView(commits: commits)
                    .padding(.vertical)
            }
            if tab == 1 {
                FileDiffsView(expandableFileDiffs: $filesChanged)
            }
        }
        .onChange(of: mergeCommit, initial: true) {
            Task {
                do {
                    commits = try await Array(Process.output(GitLog(directory: directoryURL, revisionRange: "\(mergeCommit.parentHashes[0])..\(mergeCommit.hash)")).dropFirst())
                    let diffRaw = try await Process.output(
                        GitDiff(directory: directoryURL, noRenames: false, revisionRange: mergeCommit.parentHashes[0] + ".." + mergeCommit.hash)
                    )
                    filesChanged = try Diff(raw: diffRaw).fileDiffs.map { .init(isExpanded: true, model: $0) }
                } catch {
                    self.error = error
                }
            }
        }
        .errorSheet($error)
    }
}

#Preview {
    ScrollView {
        MergeCommitContentView(
            mergeCommit: .init(
                hash: "11fff",
                parentHashes: ["21fff", "31fff"],
                author: "maoyama",
                authorEmail: "a@aoyama.dev",
                authorDate: "2014-10-10T13:50:40+09:00",
                title: "Hello world!",
                body: "body",
                branches: [],
                tags: []
            ),
            directoryURL: URL(string: "file:///maoyama/Projects/")!
        )
    }
}
