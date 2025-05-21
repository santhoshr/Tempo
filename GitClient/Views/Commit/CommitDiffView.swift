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
                    HStack {
                        HStack {
                            Text("Diff")
                            Text(selectionLogID == Log.notCommitted.id ? "Staged Changes" : selectionLogID.prefix(5))
                            Text(subSelectionLogID == Log.notCommitted.id ? "Staged Changes" : subSelectionLogID.prefix(5))
                        }
                        .foregroundStyle(.secondary)
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
                if selectionLogID == Log.notCommitted.id {
                    updateDiff(cached: true, commitRange: subSelectionLogID)
                } else if subSelectionLogID == Log.notCommitted.id {
                    updateDiff(cached: true, commitRange: selectionLogID)
                } else {
                    updateDiff(cached: false, commitRange: selectionLogID + ".." + subSelectionLogID)
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
