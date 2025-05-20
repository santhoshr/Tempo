//
//  RevisionRangeDiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/15.
//

import SwiftUI

struct RevisionRangeDiffView: View {
    @Environment(\.folder) private var folder
    var selectionLogID: String
    var subSelectionLogID: String
    @State private var commits: [Commit] = []
    @State private var filesChanges: [ExpandableModel<FileDiff>] = []
    @State private var revisionRangeText = ""
    @State private var error: Error?
    @State private var path: [String] = []
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            NavigationStack(path: $path) {
                DiffView(commits: $commits, filesChanged: $filesChanges)
                    .padding(.horizontal)
                    .navigationBarBackButtonHidden()
                    .navigationDestination(for: String.self) { commitHash in
                        CommitDetailView(commitHash: commitHash, folder: Folder(url: folder!))
                            .safeAreaInset(edge: .top, spacing: 0, content: {
                                BarBackButton(path: $path)
                            })
                    }
            }
        }
        .background(Color(NSColor.textBackgroundColor))
            .safeAreaInset(edge: .bottom, spacing: 0, content: {
                VStack(spacing: 0) {
                    Divider()
                    Spacer()
                    HStack {
                        Text("Diff")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        TextField("Revision Range", text: $revisionRangeText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 160)
                            .focused($isFocused)
                            .onSubmit {
                                updateDiff(forRevisionRange: revisionRangeText)
                            }
                            .onExitCommand {
                                isFocused = false
                            }
                    }
                    Spacer()
                }
                .background(Color(nsColor: .textBackgroundColor))
                .frame(height: 40)
            })
            .onChange(of: selectionLogID + subSelectionLogID, initial: true) { oldValue, newValue in
                revisionRangeText = rangeText(logID: subSelectionLogID).prefix(8) + "..." + rangeText(logID: selectionLogID).prefix(8)
                let revisionRange = "\(rangeText(logID: subSelectionLogID))...\(rangeText(logID: selectionLogID))"
                updateDiff(forRevisionRange: revisionRange)
            }
            .errorSheet($error)
    }

    private func rangeText(logID: String) -> String {
        if logID == Log.notCommitted.id {
            return "HEAD"
        }
        return logID
    }

    private func updateDiff(forRevisionRange revisionRange: String) {
        guard let folder else { return }
        Task {
            do {
                commits = try await Array(Process.output(GitLog(directory: folder, revisionRange: revisionRange)))
                let raw = try await Process.output(
                    GitDiff(directory: folder, noRenames: false, commitRange: revisionRange)
                )
                filesChanges = try Diff(raw: raw).fileDiffs.map { .init(isExpanded: true, model: $0) }
            } catch {
                self.error = error
            }
        }
    }
}
