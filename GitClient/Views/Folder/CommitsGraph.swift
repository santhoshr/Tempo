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
    func topologicallySortedCommits(_ commits: [Commit]) -> [Commit] {
        var graph: [String: [String]] = [:] // parent → [children]
        var inDegree: [String: Int] = [:]   // hash → number of parents
        var commitMap: [String: Commit] = [:]

        // 初期化
        for commit in commits {
            commitMap[commit.hash] = commit
            inDegree[commit.hash] = commit.parentHashes.count
            for parent in commit.parentHashes {
                graph[parent, default: []].append(commit.hash)
            }
        }

        // 親のない（in-degree 0）ノードからスタート
        var queue = commits.filter { $0.parentHashes.isEmpty }.map { $0.hash }
        var result: [Commit] = []

        while !queue.isEmpty {
            let hash = queue.removeFirst()
            if let commit = commitMap[hash] {
                result.append(commit)
            }

            for child in graph[hash] ?? [] {
                inDegree[child, default: 0] -= 1
                if inDegree[child] == 0 {
                    queue.append(child)
                }
            }
        }

        return result
    }

    func layoutCommits(_ commits: [Commit]) -> [PositionedCommit] {
        let sorted = topologicallySortedCommits(commits)

        var result: [PositionedCommit] = []
        var columnByHash: [String: Int] = [:]

        for (row, commit) in sorted.enumerated() {
            var column = 0

            if commit.parentHashes.isEmpty {
                // 最初のコミットはカラム 0
                column = 0
            } else {
                // 親のカラムを受け継ぐ
                let parentColumns = commit.parentHashes.compactMap { columnByHash[$0] }
                if let firstParentColumn = parentColumns.first {
                    column = firstParentColumn
                }
            }

            columnByHash[commit.hash] = column
            result.append(PositionedCommit(commit: commit, column: column, row: row))
        }

        return result
    }
}


struct CommitGraphView: View {
    let commits: [PositionedCommit]
    let nodeSize: CGFloat = 14
    let spacing: CGFloat = 40

    @State private var selectedCommitHash: String?

    var body: some View {
        ZStack {
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
                        }
                        .overlay(
                            Text(commit.commit.title)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .offset(x: nodeSize, y: 0),
                            alignment: .center
                        )
                }
            }
        }
        .frame(height: CGFloat(commits.count + 1) * spacing)
        .padding()
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
    CommitGraphView(commits: CommitsGraph().layoutCommits(sampleCommits))
}

#Preview {
    CommitGraphView(commits: CommitsGraph().layoutCommits(sampleCommits2))
}
