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
                        Text("Diff")
                        Text(selectionLogID.prefix(5))
                        Text(subSelectionLogID.prefix(5))
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)

                    Spacer()
                }
                .background(Color(nsColor: .textBackgroundColor))
                .frame(height: 40)
            })
            .onChange(of: selectionLogID + subSelectionLogID, initial: true) { oldValue, newValue in
                let commitRange = "\(rangeText(logID: selectionLogID))..\(rangeText(logID: subSelectionLogID))"
                updateDiff(forCommitRange: commitRange)
            }
            .errorSheet($error)
    }

    private func rangeText(logID: String) -> String {
        if logID == Log.notCommitted.id {
            return "HEAD"
        }
        return logID
    }

    private func updateDiff(forCommitRange commitRange: String) {
        guard let folder else { return }
        Task {
            do {
                let raw = try await Process.output(
                    GitDiff(directory: folder, noRenames: false, commitRange: commitRange)
                )
                filesChanges = try Diff(raw: raw).fileDiffs.map { .init(isExpanded: true, model: $0) }
            } catch {
                self.error = error
            }
        }
    }
}
