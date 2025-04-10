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
    let nodeSize: CGFloat = 10
    let spacing: CGFloat = 40

    var body: some View {
        Canvas { context, size in
            for commit in commits {
                let x = CGFloat(commit.column) * spacing + spacing
                let y = CGFloat(commit.row) * spacing + spacing

                // Draw node
                let circle = Path(ellipseIn: CGRect(x: x - nodeSize/2, y: y - nodeSize/2, width: nodeSize, height: nodeSize))
                context.stroke(circle, with: .color(.primary))

                // Draw lines to parents
                for parentID in commit.parents {
                    if let parent = commits.first(where: { $0.id == parentID }) {
                        let parentX = CGFloat(parent.column) * spacing + spacing
                        let parentY = CGFloat(parent.row) * spacing + spacing
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: parentX, y: parentY))
                        context.stroke(path, with: .color(.gray), lineWidth: 2)
                    }
                }
            }
        }
        .frame(height: CGFloat(commits.count + 1) * spacing)
    }
}

#Preview {
    CommitGraphView(commits: sampleCommits)
}
