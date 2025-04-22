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
    private func makeColumn(childColumn: Int, usingColumn: [Int]) -> Int {
        var col = childColumn + 1
        while usingColumn.contains(col) {
            col += 1
        }
        return col
    }

    func positionedCommits(topoOrderedCommits: [Commit]) -> [PositionedCommit] {
        var result: [PositionedCommit] = []
        var usingColumns: [Int] = []

        for (row, commit) in topoOrderedCommits.enumerated() {

            if row == 0 {
                // 最初のカラムは0
                result.append(PositionedCommit(commit: commit, column: 0, row: row))
                usingColumns.append(0)
            } else {
                let children = result.filter { $0.commit.parentHashes.contains { $0 == commit.hash } }
                // TODO: 子がない場合もグラフにできるようにする
                let child = children.first!
                let positioned: PositionedCommit
                if child.commit.parentHashes.count == 2, child.commit.parentHashes[1] == commit.hash {
                    let newColumn = makeColumn(childColumn: child.column, usingColumn: usingColumns)
                    positioned = PositionedCommit(commit: commit, column: newColumn, row: row)
                    usingColumns.append(newColumn)
                } else {
                    // 子のカラムを受け継ぐ
                    positioned = PositionedCommit(commit: commit, column: children.first!.column, row: row)
                }
                result.append(positioned)
                children.forEach { child in
                    if child.commit.parentHashes.count == 1 && child.column != positioned.column {
                        if let index = usingColumns.firstIndex(where: { $0 == child.column }) {
                            usingColumns.remove(at: index)
                        }
                    }
                }
            }
        }

        return result
    }
}


struct CommitGraphView: View {
    @State var commits: [PositionedCommit] = []
    @State private var selectedCommitHash: String?

    var body: some View {
        CommitGraphContentView(commits: commits, selectedCommitHash: $selectedCommitHash)
        .task {
            let store = LogStore()
            store.directory = .init(string: "file:///Users/aoyama/Projects/GitClient")

            await store.refresh()
            commits = CommitsGraph().positionedCommits(topoOrderedCommits: store.commits)
        }
    }
}

struct CommitGraphContentView: View {
    var commits: [PositionedCommit]
    let nodeSize: CGFloat = 14
    let selectedNodeSize: CGFloat = 18
    let spacing: CGFloat = 40
    let textWidth: CGFloat = 240
    @Binding var selectedCommitHash: String?

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
                            .stroke(Color.secondary.opacity(0.5), lineWidth: 6)
                        }
                    }
                }
            }

            // ノードを描く（クリック可能）
            ForEach(commits) { commit in
                if let point = position(of: commit) {
                    Circle()
                        .fill(commit.commit.hash == selectedCommitHash ? Color.blue : Color.primary)
                        .frame(
                            width: commit.commit.hash == selectedCommitHash ? selectedNodeSize: nodeSize,
                            height: commit.commit.hash == selectedCommitHash ? selectedNodeSize: nodeSize
                        )
                        .position(point)
                        .onTapGesture {
                            withAnimation {
                                selectedCommitHash = commit.commit.hash
                            }
                            print("onTap", commit)
                        }
                    Text(commit.commit.title)
                        .frame(width: textWidth, height: 20, alignment: .leading)
                        .font(.callout)
                        .foregroundStyle(commit.commit.hash == selectedCommitHash ? .primary : .secondary)
                        .position(point)
                        .offset(.init(width: 140, height: 0))
                        .onTapGesture {
                            withAnimation {
                                selectedCommitHash = commit.commit.hash
                            }
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
    ScrollView([.horizontal, .vertical]) {
        CommitGraphView()
    }
        .background(Color(NSColor.textBackgroundColor))
        .frame(width: 400, height: 600)
}

#Preview {
    @Previewable @State var selected: String?
    CommitGraphContentView(
        commits: CommitsGraph().positionedCommits(topoOrderedCommits: sampleCommits),
        selectedCommitHash: $selected
    )
        .background(Color(NSColor.textBackgroundColor))
        .frame(width: 400, height: 600)
}

#Preview {
    @Previewable @State var selected: String?
    CommitGraphContentView(
        commits: CommitsGraph().positionedCommits(topoOrderedCommits: sampleCommits2),
        selectedCommitHash: $selected
    )
        .background(Color(NSColor.textBackgroundColor))
        .frame(width: 400, height: 600)
}
