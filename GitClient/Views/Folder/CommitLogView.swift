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
    @Binding var error: Error?
    var onCheckout: () -> Void
    var onRevert: () -> Void

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
                    .contextMenu {
                        Button("Checkout") {
                            Task {
                                do {
                                    try await Process.output(GitCheckout(directory: folder!, commitHash: commit.hash))
                                    onCheckout()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        Button("Revert" + (commit.parentHashes.count == 2 ? " -m 1 (\(commit.parentHashes[0].prefix(7)))" : "")) {
                            Task {
                                do {
                                    if commit.parentHashes.count == 2 {
                                        try await Process.output(GitRevert(directory: folder!,  parentNumber: 1, commit: commit.hash))
                                    } else {
                                        try await Process.output(GitRevert(directory: folder!, commit: commit.hash))
                                    }
                                    onRevert()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        Button("Tag") {
                            showing.createNewTagAt = commit
                        }
                        if commit == logStore.commits.first {
                            if let notCommitted = logStore.notCommitted {
                                if notCommitted.diffCached.isEmpty {
                                    Button("Amend") {
                                        showing.amendCommitAt = commit
                                    }
                                }
                            } else {
                                Button("Amend") {
                                    showing.amendCommitAt = commit
                                }
                            }
                        }
                    }
            }
        }
    }

}
