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

    var body: some View {
        ScrollView {
            DiffView(commits: $commits, filesChanged: $filesChanges)
                .padding(.horizontal)
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
                            .onSubmit {
                                guard let folder else { return }
                                Task {
                                    do {
                                        commits = try await Array(Process.output(GitLog(directory: folder, revisionRange: revisionRangeText)))
                                        let raw = try await Process.output(
                                            GitDiff(directory: folder, noRenames: false, revisionRange: revisionRangeText)
                                        )
                                        filesChanges = try Diff(raw: raw).fileDiffs.map { .init(isExpanded: true, model: $0) }
                                    } catch {
                                        self.error = error
                                    }
                                }
                            }
                    }
                    Spacer()
                }
                .background(Color(nsColor: .textBackgroundColor))
                .frame(height: 40)
            })
            .onChange(of: selectionLogID + subSelectionLogID, initial: true) { oldValue, newValue in
                Task {
                    guard let folder else { return }
                    do {
                        revisionRangeText = rangeText(logID: subSelectionLogID).prefix(8) + "..." + rangeText(logID: selectionLogID).prefix(8)
                        let revisionRange = "\(rangeText(logID: subSelectionLogID))...\(rangeText(logID: selectionLogID))"
                        commits = try await Array(Process.output(GitLog(directory: folder, revisionRange: revisionRange)))
                        let raw = try await Process.output(
                            GitDiff(directory: folder, noRenames: false, revisionRange: revisionRange)
                        )
                        filesChanges = try Diff(raw: raw).fileDiffs.map { .init(isExpanded: true, model: $0) }
                    } catch {
                        self.error = error
                    }
                }
            }
            .errorSheet($error)
    }

    private func rangeText(logID: String) -> String {
        if logID == Log.notCommitted.id {
            return "HEAD"
        }
        return logID
    }
}
