//
//  CommitGraph.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/11.
//

import SwiftUI

struct CommitGraph {
    private func makeColumn(childColumn: Int, usingColumn: [Int]) -> Int {
        var col = childColumn + 1
        while usingColumn.contains(col) {
            col += 1
        }
        return col
    }

    func positionedCommits(_ commits: [Commit]) -> [PositionedCommit] {
        var result: [PositionedCommit] = []
        var usingColumns: [Int] = []

        for (row, commit) in commits.enumerated() {
            if row == 0 {
                // 最初のカラムは0
                result.append(PositionedCommit(commit: commit, column: 0, row: row))
                usingColumns.append(0)
            } else {
                let children = result.filter { $0.commit.parentHashes.contains { $0 == commit.hash } }
                if children.isEmpty { // 検索条件で子のコミットがない時
                    let positioned = PositionedCommit(commit: commit, column: result[row - 1].column, row: row, childrenIsHidden: true)
                    result.append(positioned)
                } else {
                    let positioned: PositionedCommit
                    if let childColumn = children.filter({ $0.commit.parentHashes[0] == commit.hash }).map({ $0.column }).min() {
                        // 子のカラムを受け継ぐ。新しいカラムを必要としない場合
                        positioned = PositionedCommit(commit: commit, column: childColumn, row: row)
                    } else {
                        let newColumn = makeColumn(childColumn: children[0].column, usingColumn: usingColumns)
                        positioned = PositionedCommit(commit: commit, column: newColumn, row: row)
                        usingColumns.append(newColumn)
                    }
                    result.append(positioned)
                    children.forEach { child in
                        if child.column != positioned.column {
                            if let index = usingColumns.firstIndex(where: { $0 == child.column }) {
                                usingColumns.remove(at: index)
                            }
                        }
                    }
                }
            }
        }

        return result
    }
}

struct PositionedCommit: Identifiable {
    var id: String { commit.hash }

    let commit: Commit
    let column: Int
    let row: Int
    var childrenIsHidden: Bool = false
}

struct CommitGraphView: View {
    @Binding var logStore: LogStore
    @Binding var selectedCommitHash: String?

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            CommitGraphContentView(commits: CommitGraph().positionedCommits(logStore.commits), selectedCommitHash: $selectedCommitHash)
        }
        .background(Color(NSColor.textBackgroundColor))
    }
}

struct CommitGraphContentView: View {
    var commits: [PositionedCommit]
    let nodeSize: CGFloat = 16
    let selectedNodeSize: CGFloat = 20
    let spacing: CGFloat = 40
    let textWidth: CGFloat = 240
    @Binding var selectedCommitHash: String?

    var body: some View {
        ZStack(alignment:.leading) {
            // 線（親子関係）を描く
            ForEach(commits) { commit in
                if let from = position(of: commit) {
                    ForEach(commit.commit.parentHashes, id: \.self) { parentHash in
                        if let parent = commits.first(where: { $0.commit.hash == parentHash }), !parent.childrenIsHidden , let to = position(of: parent) {
                            Path { path in
                                path.move(to: from)
                                path.addLine(to: to)
                            }
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 6)
                        }
                    }
                }
            }

            // ノードを描く（クリック可能）
            ForEach(commits) { commit in
                if let point = position(of: commit) {
                    Circle()
                        .fill(commit.commit.hash == selectedCommitHash ? Color.blue : Color.primary)
                        .overlay(
                            Circle()
                                .stroke(Color(NSColor.textBackgroundColor), lineWidth: 2)
                        )
                        .frame(
                            width: commit.commit.hash == selectedCommitHash ? selectedNodeSize: nodeSize,
                            height: commit.commit.hash == selectedCommitHash ? selectedNodeSize: nodeSize
                        )
                        .position(point)
                        .onTapGesture {
                            selectedCommitHash = commit.commit.hash
                            print("onTap", commit)
                        }
                    Text(commit.commit.title)
                        .frame(width: textWidth, height: 20, alignment: .leading)
                        .font(.callout)
                        .foregroundStyle(commit.commit.hash == selectedCommitHash ? .primary : .secondary)
                        .position(point)
                        .offset(.init(width: 140, height: 0))
                        .onTapGesture {

                            selectedCommitHash = commit.commit.hash

                            print("onTap", commit)
                        }
                }
            }
        }
        .frame(
            width: CGFloat((commits.map { $0.column }.max() ?? 0) + 2) * spacing + textWidth,
            height: CGFloat(commits.count + 1) * spacing
        )
    }

    private func position(of commit: PositionedCommit) -> CGPoint? {
        var p = CGPoint(
            x: CGFloat(commit.column) * spacing + spacing,
            y: CGFloat(commit.row) * spacing + spacing
        )
        if commit.childrenIsHidden {
            p.x += 0.5 * spacing
        }
        return p
    }
}

#Preview {
    @Previewable @State var selected: String?
    let sampleCommits = [
        Commit(hash: "d", parentHashes: ["b", "c"], author: "Dave", authorEmail: "", authorDate: "2023-10-04T12:00:00Z", title: "Merge feature", body: "", branches: [], tags: []),
        Commit(hash: "c", parentHashes: ["b"], author: "Carol", authorEmail: "", authorDate: "2023-10-03T12:00:00Z", title: "Fix bug", body: "", branches: [], tags: []),
        Commit(hash: "b", parentHashes: ["a"], author: "Bob", authorEmail: "", authorDate: "2023-10-02T12:00:00Z", title: "Add feature", body: "", branches: [], tags: []),
        Commit(hash: "a", parentHashes: [], author: "Alice", authorEmail: "", authorDate: "2023-10-01T12:00:00Z", title: "Initial commit", body: "", branches: [], tags: [])
    ]

    CommitGraphContentView(
        commits: CommitGraph().positionedCommits(sampleCommits),
        selectedCommitHash: $selected
    )
        .background(Color(NSColor.textBackgroundColor))
        .frame(width: 400, height: 600)
}

#Preview {
    @Previewable @State var selected: String?
    let sampleCommits2 = [
        Commit(hash: "f", parentHashes: ["d", "e"], author: "Frank", authorEmail: "", authorDate: "2023-10-06T12:00:00Z", title: "Merge bugfix", body: "", branches: [], tags: []),
        Commit(hash: "e", parentHashes: ["c"], author: "Eve", authorEmail: "", authorDate: "2023-10-05T12:00:00Z", title: "Bugfix", body: "", branches: [], tags: []),
        Commit(hash: "d", parentHashes: ["b", "c"], author: "Dave", authorEmail: "", authorDate: "2023-10-04T12:00:00Z", title: "Merge feature", body: "", branches: [], tags: []),
        Commit(hash: "c", parentHashes: ["b"], author: "Carol", authorEmail: "", authorDate: "2023-10-03T12:00:00Z", title: "Fix bug", body: "", branches: [], tags: []),
        Commit(hash: "b", parentHashes: ["a"], author: "Bob", authorEmail: "", authorDate: "2023-10-02T12:00:00Z", title: "Add feature", body: "", branches: [], tags: []),
        Commit(hash: "a", parentHashes: [], author: "Alice", authorEmail: "", authorDate: "2023-10-01T12:00:00Z", title: "Initial commit", body: "", branches: [], tags: [])
    ]

    CommitGraphContentView(
        commits: CommitGraph().positionedCommits(sampleCommits2),
        selectedCommitHash: $selected
    )
        .background(Color(NSColor.textBackgroundColor))
        .frame(width: 400, height: 600)
}

#Preview("In Search") {
    @Previewable @State var selected: String?
    let sampleCommitsInSearch = [
        Commit(hash: "f", parentHashes: ["d", "e"], author: "Frank", authorEmail: "", authorDate: "2023-10-06T12:00:00Z", title: "Merge bugfix", body: "", branches: [], tags: []),
        Commit(hash: "e", parentHashes: ["c"], author: "Eve", authorEmail: "", authorDate: "2023-10-05T12:00:00Z", title: "Bugfix", body: "", branches: [], tags: []),
        Commit(hash: "d", parentHashes: ["b", "c"], author: "Dave", authorEmail: "", authorDate: "2023-10-04T12:00:00Z", title: "Merge feature", body: "", branches: [], tags: []),
        Commit(hash: "x", parentHashes: ["b"], author: "Carol", authorEmail: "", authorDate: "2023-10-03T12:00:00Z", title: "Fix bug", body: "", branches: [], tags: []),
        Commit(hash: "b", parentHashes: ["a"], author: "Bob", authorEmail: "", authorDate: "2023-10-02T12:00:00Z", title: "Add feature", body: "", branches: [], tags: []),
        Commit(hash: "a'", parentHashes: [], author: "Alice", authorEmail: "", authorDate: "2023-10-01T12:00:00Z", title: "Initial commit", body: "", branches: [], tags: [])
    ]

    CommitGraphContentView(
        commits: CommitGraph().positionedCommits( sampleCommitsInSearch),
        selectedCommitHash: $selected
    )
        .background(Color(NSColor.textBackgroundColor))
        .frame(width: 400, height: 600)
}
