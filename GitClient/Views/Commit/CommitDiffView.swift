//
//  CommitDiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/15.
//

import SwiftUI

struct CommitDiffView: View {
    @Environment(\.folder) private var folder
    var selectionLogID: String
    var subSelectionLogID: String

    @State private var commitFirst = ""
    @State private var commitSecond = ""
    @State private var filesChanges: [ExpandableModel<FileDiff>] = []
    @State private var shortstat = ""
    @State private var error: Error?
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            FileDiffsView(expandableFileDiffs: $filesChanges)
                .padding(.horizontal)
        }
        .background(Color(NSColor.textBackgroundColor))
            .safeAreaInset(edge: .bottom, spacing: 0, content: {
                VStack(spacing: 0) {
                    Divider()
                    Spacer()
                    HStack(spacing: 0) {
                        HStack {
                            Text("Diff")
                                .foregroundStyle(.secondary)
                            Text(commitFirst == Log.notCommitted.id ? "Staged Changes" : commitFirst.prefix(5))
                            Text(commitSecond == Log.notCommitted.id ? "Staged Changes" : commitSecond.prefix(5))
                            Button {
                                let first = commitFirst
                                let second = commitSecond
                                commitFirst = second
                                commitSecond = first
                            } label: {
                                Image(systemName: "arrow.left.arrow.right")
                            }
                                .buttonStyle(.accessoryBar)
                                .help("Swap the Commits")
                        }
                        .padding(.horizontal)
                        Divider()
                        Spacer()
                        Text(shortstat)
                            .minimumScaleFactor(0.3)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .font(.callout)

                    Spacer()
                }
                .background(Color(nsColor: .textBackgroundColor))
                .frame(height: 40)
            })
            .onChange(of: selectionLogID + subSelectionLogID, initial: true) { oldValue, newValue in
                commitFirst = selectionLogID
                commitSecond = subSelectionLogID
            }
            .onChange(of: commitFirst + commitSecond, initial: true) { _, _ in
                if commitFirst == Log.notCommitted.id {
                    updateDiff(cached: true, commitRange: commitSecond)
                } else if commitSecond == Log.notCommitted.id {
                    updateDiff(cached: true, commitRange: commitFirst)
                } else {
                    updateDiff(cached: false, commitRange: commitFirst + ".." + commitSecond)
                }
            }
            .errorSheet($error)
    }

    private func updateDiff(cached: Bool, commitRange: String) {
        guard let folder else { return }
        Task {
            do {
                let raw = try await Process.output(
                    GitDiff(directory: folder, noRenames: false, cached: cached, commitRange: commitRange)
                )
                filesChanges = try Diff(raw: raw).fileDiffs.map { .init(isExpanded: true, model: $0) }
                shortstat = try await Process.output(
                    GitDiff(directory: folder, noRenames: false, shortstat: true, cached: cached, commitRange: commitRange)
                ).trimmingCharacters(in: .whitespacesAndNewlines)

            } catch {
                self.error = error
            }
        }
    }
}
