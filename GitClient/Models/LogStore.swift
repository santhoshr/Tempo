//
//  LogStore.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/03.
//

import Foundation

final class LogStore: ObservableObject {
    var directory: URL
    @Published private(set)var logs: [Log]
    @Published var error: Error?

    init(directory: URL, logs: [Log]=[]) {
        self.directory = directory
        self.logs = logs
    }

    /// 最新500件取得しlogsを差し替え
    func refresh() async {
        // git log -n 500
        do {
            var newLogs = try await Process.output(GitLog(directory: directory)).map { Log.committed($0) }
            let newNotCommitted = try await notCommited()
            if !newNotCommitted.isEmpty {
                newLogs.insert(.notCommitted, at: 0)
            }
            logs = newLogs
        } catch {
            self.error = error
        }
    }

    /// logsを全てを最新に更新しlogs.first以降のコミットを取得し追加
    func update() async {
        // git log -n logs.count logs.first.commitHash


        // git log logs.first.commitHash..
    }

    /// logビューの表示時に呼び出しし必要に応じてlogsを追加読み込み
    func logViewTask(_ log: Log) async {

    }

    private func notCommited() async throws -> NotCommitted {
        let gitDiff = try await Process.output(GitDiff(directory: directory))
        let gitDiffCached = try await Process.output(GitDiffCached(directory: directory))
        let status = try await Process.output(GitStatus(directory: directory))
        return  NotCommitted(diff: gitDiff, diffCached: gitDiffCached, status: status)
    }

    /// logs.last以前のコミットを取得し追加
    private func loadMore() async {
        // git log -n 500 logs.last.commitHash^
    }
}
