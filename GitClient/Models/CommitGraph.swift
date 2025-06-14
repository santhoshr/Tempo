//
//  CommitGraph.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/06/14.
//


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
                        // parentHashesが1でない時はマージコミットであり、別の親がカラムをまだ利用するため
                        if child.column != positioned.column && child.commit.parentHashes.count == 1 {
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

