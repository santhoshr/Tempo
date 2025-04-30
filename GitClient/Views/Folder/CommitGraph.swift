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
    @Binding var selectionLogID: String?

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            CommitGraphContentView(
                notCommitted: logStore.notCommitted,
                commits: CommitGraph().positionedCommits(logStore.commits),
                selectionLogID: $selectionLogID)
        }
        .background(Color(NSColor.textBackgroundColor))
    }
}

struct CommitGraphContentView: View {
    var notCommitted: NotCommitted?
    var commits: [PositionedCommit]
    let xSpacing: CGFloat = 26
    let ySpacing: CGFloat = 42
    let textWidth: CGFloat = 180
    let textHeight: CGFloat = 38
    @Binding var selectionLogID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let _ = notCommitted {
                HStack (spacing: selectionLogID == Log.notCommitted.id ? 6 : 8) {
                    GraphNode(
                        logID: Log.notCommitted.id,
                        selectionLogID: $selectionLogID
                    )
                    GraphNodeText(logID: Log.notCommitted.id, title: "Not Committed", selectionLogID: $selectionLogID)
                }
                .padding(
                    .horizontal,
                    xSpacing - (selectionLogID == Log.notCommitted.id ? GraphNode.selectedNodeSize : GraphNode.nodeSize) / 2
                )
            }

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

                // ノードを描く
                ForEach(commits) { commit in
                    if let point = position(of: commit) {
                        GraphNode(
                            logID: commit.id,
                            selectionLogID: $selectionLogID
                        )
                            .position(point)
                        GraphNodeText(
                            logID: commit.id,
                            title: commit.commit.title,
                            selectionLogID: $selectionLogID
                        )
                            .frame(width: textWidth, height: textHeight, alignment: .leading)
                            .offset(.init(width: textWidth / 2 + 14, height: 0))
                            .position(point)
                    }
                }
            }
            .frame(
                width: CGFloat((commits.map { $0.column }.max() ?? 0) + 1) * xSpacing + textWidth + 18*2,
                height: CGFloat(commits.count + 1) * ySpacing
            )
        }
    }

    private func position(of commit: PositionedCommit) -> CGPoint? {
        var p = CGPoint(
            x: CGFloat(commit.column) * xSpacing + xSpacing,
            y: CGFloat(commit.row) * ySpacing + xSpacing
        )
        if commit.childrenIsHidden {
            p.x += 0.5 * xSpacing
        }
        return p
    }
}

struct GraphNode: View {
    static let nodeSize: CGFloat = 14
    static let selectedNodeSize: CGFloat = 18
    var logID: String
    @Binding var selectionLogID: String?

    var body: some View {
        Circle()
            .fill(logID == selectionLogID ? Color.blue : Color.primary)
            .overlay(
                Circle()
                    .stroke(Color(NSColor.textBackgroundColor), lineWidth: 2)
            )
            .frame(
                width: logID == selectionLogID ? Self.selectedNodeSize: Self.nodeSize,
                height: logID == selectionLogID ? Self.selectedNodeSize: Self.nodeSize
            )
            .onTapGesture {
                selectionLogID = logID
            }
    }
}

struct GraphNodeText: View {
    var logID: String
    var title: String
    @Binding var selectionLogID: String?

    var body: some View {
        VStack {
            Text(title)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
        }
            .font(.callout)
            .foregroundStyle(logID == selectionLogID ? Color(nsColor: .textBackgroundColor) : .secondary)
            .background {
                if logID == selectionLogID {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                }
            }
            .onTapGesture {
                selectionLogID = logID
            }
    }
}

#Preview {
    @Previewable @State var selected: String?
    let sampleCommits = [
        Commit(hash: "d", parentHashes: ["b", "c"], author: "Dave", authorEmail: "", authorDate: "2023-10-04T12:00:00Z", title: "Merge feature", body: "", branches: [], tags: []),
        Commit(hash: "c", parentHashes: ["b"], author: "Carol", authorEmail: "", authorDate: "2023-10-03T12:00:00Z", title: "Fix bug Fix bug Fix bug Fix bug Fix bug Fix bug Fix bug Fix bug Fix bug", body: "", branches: [], tags: []),
        Commit(hash: "b", parentHashes: ["a"], author: "Bob", authorEmail: "", authorDate: "2023-10-02T12:00:00Z", title: "Add feature", body: "", branches: [], tags: []),
        Commit(hash: "a", parentHashes: [], author: "Alice", authorEmail: "", authorDate: "2023-10-01T12:00:00Z", title: "Initial commit", body: "", branches: [], tags: [])
    ]

    CommitGraphContentView(
        notCommitted: .init(diff: "hi", diffCached: "hello", status: .init(untrackedFiles: [])),
        commits: CommitGraph().positionedCommits(sampleCommits),
        selectionLogID: $selected
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
        selectionLogID: $selected
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
        selectionLogID: $selected
    )
        .background(Color(NSColor.textBackgroundColor))
        .frame(width: 400, height: 600)
}

