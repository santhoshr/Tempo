//
//  LogStore.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/03.
//

import Foundation

final class LogStore: ObservableObject {
    let number = 500
    var directory: URL
    @Published var commits: [Commit]
    @Published var notCommitted: NotCommitted?
    var logs: [Log] {
        var logs = commits.map { Log.committed($0) }
        if let notCommitted, !notCommitted.isEmpty {
            logs.insert(.notCommitted, at: 0)
        }
        return logs
    }
    @Published var error: Error?

    init(directory: URL, commits: [Commit]=[]) {
        self.directory = directory
        self.commits = commits
    }

    /// 最新500件取得しlogsを差し替え
    func refresh() async {
        do {
            notCommitted = try await notCommited()
            commits = try await Process.output(GitLog(directory: directory, number: number))
        } catch {
            self.error = error
        }
    }

    /// logsを全てを最新に更新しlogs.first以降のコミットを取得し追加
    func update() async {
        do {
            notCommitted = try await notCommited()
            let current = try await Process.output(GitLog(directory: directory, number: commits.count, revisionRange: commits.first?.hash ?? ""))
            let adding = try await Process.output(GitLog(directory: directory, revisionRange: commits.first.map { $0.hash + ".."} ?? ""))
            commits = adding + current
        } catch {
            self.error = error
        }
    }

    /// logビューの表示時に呼び出しし必要に応じてlogsを追加読み込み
    func logViewTask(_ log: Log) async {
        switch log {
        case .notCommitted:
            return
        case .committed(let commit):
            if commit == commits.last {
                await loadMore()
            }
        }
    }

    private func notCommited() async throws -> NotCommitted {
        let gitDiff = try await Process.output(GitDiff(directory: directory))
        let gitDiffCached = try await Process.output(GitDiffCached(directory: directory))
        let status = try await Process.output(GitStatus(directory: directory))
        return NotCommitted(diff: gitDiff, diffCached: gitDiffCached, status: status)
    }

    /// logs.last以前のコミットを取得し追加
    private func loadMore() async {
        guard let last = commits.last else { return }
        do {
            commits += try await Process.output(GitLog(directory: directory, number: number, revisionRange: last.hash + "^"))

        } catch {
            self.error = error
        }
    }
}
