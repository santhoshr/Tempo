//
//  CommitsGraph.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/11.
//

import SwiftUI

let sampleCommits = [
    Commit(hash: "d", parentHashes: ["b", "c"], author: "Dave", authorEmail: "", authorDate: "2023-10-04T12:00:00Z", title: "Merge feature", body: "", branches: [], tags: []),
    Commit(hash: "c", parentHashes: ["b"], author: "Carol", authorEmail: "", authorDate: "2023-10-03T12:00:00Z", title: "Fix bug", body: "", branches: [], tags: []),
    Commit(hash: "b", parentHashes: ["a"], author: "Bob", authorEmail: "", authorDate: "2023-10-02T12:00:00Z", title: "Add feature", body: "", branches: [], tags: []),
    Commit(hash: "a", parentHashes: [], author: "Alice", authorEmail: "", authorDate: "2023-10-01T12:00:00Z", title: "Initial commit", body: "", branches: [], tags: [])
]

let sampleCommits2 = [
    Commit(hash: "f", parentHashes: ["d", "e"], author: "Frank", authorEmail: "", authorDate: "2023-10-06T12:00:00Z", title: "Merge bugfix", body: "", branches: [], tags: []),
    Commit(hash: "e", parentHashes: ["c"], author: "Eve", authorEmail: "", authorDate: "2023-10-05T12:00:00Z", title: "Bugfix", body: "", branches: [], tags: []),
    Commit(hash: "d", parentHashes: ["b", "c"], author: "Dave", authorEmail: "", authorDate: "2023-10-04T12:00:00Z", title: "Merge feature", body: "", branches: [], tags: []),
    Commit(hash: "c", parentHashes: ["b"], author: "Carol", authorEmail: "", authorDate: "2023-10-03T12:00:00Z", title: "Fix bug", body: "", branches: [], tags: []),
    Commit(hash: "b", parentHashes: ["a"], author: "Bob", authorEmail: "", authorDate: "2023-10-02T12:00:00Z", title: "Add feature", body: "", branches: [], tags: []),
    Commit(hash: "a", parentHashes: [], author: "Alice", authorEmail: "", authorDate: "2023-10-01T12:00:00Z", title: "Initial commit", body: "", branches: [], tags: [])
]


struct CommitsGraph {
    func positionedCommits(topoOrderedCommits: [Commit]) -> [PositionedCommit] {
        var result: [PositionedCommit] = []

        for (row, commit) in topoOrderedCommits.enumerated() {

            if row == 0 {
                // 最初のカラムは0
                result.append(PositionedCommit(commit: commit, column: 0, row: row))
            } else {
                let children = result.filter { $0.commit.parentHashes.contains { $0 == commit.hash } }
                let child = children.first!
                if child.commit.parentHashes.count == 2, child.commit.parentHashes[1] == commit.hash {
                    result.append(PositionedCommit(commit: commit, column: child.column + 1, row: row))
                } else {
                    // 子のカラムを受け継ぐ
                    result.append(PositionedCommit(commit: commit, column: children.first!.column, row: row))
                }
            }
        }

        return result
    }
}


struct CommitGraphView: View {
    @State var commits: [PositionedCommit] = []
    let nodeSize: CGFloat = 14
    let spacing: CGFloat = 40

    @State private var selectedCommitHash: String?

    var body: some View {
        ZStack(alignment:.leading) {
            // 線（親子関係）を描く
            ForEach(commits) { commit in
                if let from = position(of: commit) {
                    ForEach(commit.commit.parentHashes, id: \.self) { parentHash in
                        if let parent = commits.first(where: { $0.commit.hash == parentHash }),
                           let to = position(of: parent) {
                            Path { path in
                                path.move(to: from)
                                path.addLine(to: to)
                            }
                            .stroke(Color.gray, lineWidth: 2)
                        }
                    }
                }
            }

            // ノードを描く（クリック可能）
            ForEach(commits) { commit in
                if let point = position(of: commit) {
                    Circle()
                        .fill(commit.commit.hash == selectedCommitHash ? Color.blue : Color.primary)
                        .frame(width: nodeSize, height: nodeSize)
                        .position(point)
                        .onTapGesture {
                            selectedCommitHash = commit.commit.hash
                            print("onTap", commit)
                        }
                    Text(commit.commit.title)
                        .frame(width: 200, height: 20, alignment: .leading)
                        .background(Color.cyan)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .position(point)
                        .offset(.init(width: 120, height: 0))
                }
            }
        }
        .frame(height: CGFloat(commits.count + 1) * spacing)
        .padding()
        .task {
            let store = LogStore()
            store.directory = .init(string: "file://///Users/aoyama/Projects/GitClient")

            await store.refresh()
            commits = CommitsGraph().positionedCommits(topoOrderedCommits: store.commits)
        }
    }

    private func position(of commit: PositionedCommit) -> CGPoint? {
        CGPoint(
            x: CGFloat(commit.column) * spacing + spacing,
            y: CGFloat(commit.row) * spacing + spacing
        )
    }
}

struct PositionedCommit: Identifiable {
    let commit: Commit
    let column: Int
    let row: Int

    var id: String { commit.hash }
}

#Preview {
    ScrollView {
        CommitGraphView()
    }
        .frame(width: 600, height: 600)
}

#Preview {
    CommitGraphView()
}
