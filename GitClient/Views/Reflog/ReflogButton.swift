//
//  ReflogButton.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import SwiftUI

struct ReflogButton: View {
    var folder: Folder
    @Binding var showing: FolderViewShowing
    var onRefresh: () async -> Void
    @Binding var error: Error?
    @Binding var selectionLog: Log?
    @Binding var originalBranchForReturn: String?

    var body: some View {
        Button {
            showing.reflog.toggle()
        } label: {
            Image(systemName: "clock.arrow.circlepath")
        }
        .help("Show Reflog")
        .popover(isPresented: $showing.reflog, content: {
            ReflogView(
                folder: folder,
                onPreview: { entry in
                    showing.reflog = false
                    // Preview mode: just show the commit in UI, no git operations
                    Task {
                        do {
                            let commits = try await Process.output(GitLog(directory: folder.url))
                            if let matchingCommit = commits.first(where: { $0.hash == entry.hash }) {
                                await MainActor.run {
                                    selectionLog = .committed(matchingCommit)
                                }
                            }
                        } catch {
                            self.error = error
                        }
                    }
                },
                onCheckout: { entry in
                    // Store original branch before doing actual checkout
                    Task {
                        do {
                            // Store the current branch before checkout (only if we're on a real branch)
                            if originalBranchForReturn == nil {
                                let currentBranch = try await Process.output(GitBranch(directory: folder.url)).current
                                if let branch = currentBranch, !branch.isDetached {
                                    await MainActor.run {
                                        originalBranchForReturn = branch.name
                                    }
                                }
                            }
                        } catch {
                            // Continue with checkout even if branch detection fails
                        }
                    }
                    showing.reflog = false
                    Task {
                        do {
                            if !entry.branchNames.isEmpty {
                                // Switch to branch instead of detached HEAD
                                try await Process.output(GitSwitch(directory: folder.url, branchName: entry.branchNames.first!))
                            } else {
                                try await Process.output(GitCheckout(directory: folder.url, commitHash: entry.hash))
                            }
                            await onRefresh()
                        } catch {
                            self.error = error
                        }
                    }
                }
            )
            .frame(width: 400, height: 500)
            .padding()
        })
    }
}