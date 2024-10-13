//
//  MergeCommitContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/13.
//

import SwiftUI

struct MergeCommitContentView: View {
    var mergeCommit: CommitDetail

    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "arrow.triangle.merge")
            Text("2 parents")
            NavigationLink(mergeCommit.abbreviatedParentHashes[0], value: mergeCommit.abbreviatedParentHashes[0])
            Text("+")
            NavigationLink(mergeCommit.abbreviatedParentHashes[1], value: mergeCommit.abbreviatedParentHashes[1])
        }
    }
}

#Preview {
    MergeCommitContentView(mergeCommit: .init(
        hash: "11fff",
        abbreviatedParentHashes: ["21fff", "31fff"],
        author: "maoyama",
        authorEmail: "a@aoyama.dev",
        authorDate: "1 seconds ago",
        title: "Hello world!",
        body: "body",
        branches: [],
        tags: [],
        diff: try! Diff(raw: ""))
    )
}
