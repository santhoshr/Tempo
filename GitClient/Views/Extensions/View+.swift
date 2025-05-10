//
//  View+.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import SwiftUI

extension View {
    func errorSheet(_ error: Binding<Error?>) -> some View {
        sheet(isPresented: .constant(error.wrappedValue != nil)) {
            ErrorTextSheet(error: error)
        }
    }

    func commitContextMenu(
        folder: URL,
        commit: Commit,
        logStore: LogStore,
        isRefresh: Binding<Bool>,
        showing: Binding<FolderViewShowing>,
        bindingError: Binding<Error?>
    ) -> some View {
        contextMenu{
            Button("Checkout") {
                Task {
                    do {
                        try await Process.output(GitCheckout(directory: folder, commitHash: commit.hash))
                        isRefresh.wrappedValue = true
                    } catch {
                        bindingError.wrappedValue = error
                    }
                }
            }
            Button("Revert" + (commit.parentHashes.count == 2 ? " -m 1 (mainline:  \(commit.parentHashes[0].prefix(7)))" : "")) {
                Task {
                    do {
                        if commit.parentHashes.count == 2 {
                            try await Process.output(GitRevert(directory: folder,  parentNumber: 1, commit: commit.hash))
                        } else {
                            try await Process.output(GitRevert(directory: folder, commit: commit.hash))
                        }
                        isRefresh.wrappedValue = true
                    } catch {
                        bindingError.wrappedValue = error
                    }
                }
            }
            if commit == logStore.commits.first {
                if let notCommitted = logStore.notCommitted {
                    if notCommitted.diffCached.isEmpty {
                        Button("Amend") {
                            showing.wrappedValue.amendCommitAt = commit
                        }
                    }
                } else {
                    Button("Amend") {
                        showing.wrappedValue.amendCommitAt = commit
                    }
                }
            }
            Button("Tag") {
                showing.wrappedValue.createNewTagAt = commit
            }
        }
    }
}
