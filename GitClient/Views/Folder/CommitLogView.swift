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
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                countText()
                    .font(.callout)
                    .padding(12)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(alignment: .trailing) {
                Image(systemName: "g.circle")
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }

    fileprivate func countText() -> some View {
        if let count = logStore.totalCommitsCount {
            let subText: String
            if count == 1 {
                subText = "Commit"
            } else {
                subText = "Commits"
            }
            return Text("\(count) \(subText)")
        } else {
            return Text("")
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
                                    isRefresh = true
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
                                    isRefresh = true
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
