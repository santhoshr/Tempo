//
//  CommitsGraph.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/11.
//

import SwiftUI

struct CommitNode: Identifiable {
    let id: String
    let column: Int // ブランチのインデックス
    let row: Int    // タイムライン順
    let isMerge: Bool
    let parents: [String]
}

let sampleCommits = [
    CommitNode(id: "a", column: 0, row: 0, isMerge: false, parents: []),
    CommitNode(id: "b", column: 0, row: 1, isMerge: false, parents: ["a"]),
    CommitNode(id: "c", column: 1, row: 2, isMerge: false, parents: ["b"]),
    CommitNode(id: "d", column: 0, row: 3, isMerge: true, parents: ["b", "c"])
]

struct CommitGraphView: View {
    let commits: [CommitNode]
    let nodeSize: CGFloat = 14
    let spacing: CGFloat = 40

    @State private var selectedCommitID: String?

    var body: some View {
        ZStack {
            // 線を描く
            ForEach(commits) { commit in
                if let from = position(of: commit) {
                    ForEach(commit.parents, id: \.self) { parentID in
                        if let parent = commits.first(where: { $0.id == parentID }),
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
                        .fill(commit.id == selectedCommitID ? Color.blue : Color.primary)
                        .frame(width: nodeSize, height: nodeSize)
                        .position(point)
                        .onTapGesture {
                            selectedCommitID = commit.id
                        }
                        .overlay(
                            Text(commit.id)
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

    private func position(of commit: CommitNode) -> CGPoint? {
        CGPoint(
            x: CGFloat(commit.column) * spacing + spacing,
            y: CGFloat(commit.row) * spacing + spacing
        )
    }
}

#Preview {
    CommitGraphView(commits: sampleCommits)
}
