//
//  LogStore.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/03.
//

import Foundation

final class LogStore {
    var logs: [Log] = []

    /// 最新500件取得しlogsを差し替え
    func refresh() async {
        // git log -n 500
    }

    /// logsを全てを最新に更新しlogs.first以降のコミットを取得し追加
    func update() async {
        // git log -n logs.count logs.first.commitHash
        // git log logs.first.commitHash..
    }

    /// logs.last以前のコミットを取得し追加
    private func loadMore() async {
        // git log -n 500 logs.last.commitHash^
    }

    /// logビューの表示時に呼び出しし必要に応じてlogsを追加読み込み
    func logViewTask(_ log: Log) async {

    }
}
