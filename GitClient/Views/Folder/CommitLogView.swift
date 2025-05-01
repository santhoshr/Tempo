//
//  CommitLogView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/23.
//

import SwiftUI

struct CommitLogView: View {
    @Environment(\.folder) private var folder
    @Binding var logStore: LogStore
    @Binding var selectionLogID: String?
    @Binding var showing: FolderViewShowing
    @Binding var isRefresh: Bool
    @Binding var error: Error?

    var body: some View {
        List(logStore.logs(), selection: $selectionLogID) { log in
            logsRow(log)
                .task {
                    await logStore.logViewTask(log)
                }
        }
    }

    fileprivate func logsRow(_ log: Log) -> some View {
        return VStack {
            switch log {
            case .notCommitted:
                Text("Not Committed")
                    .foregroundStyle(Color.secondary)
            case .committed(let commit):
                CommitRowView(commit: commit)
                    .commitContextMenu(
                        folder: folder!,
                        commit: commit,
                        logStore: logStore,
                        isRefresh: $isRefresh,
                        showing: $showing,
                        bindingError: $error
                    )
            }
        }
    }

}
