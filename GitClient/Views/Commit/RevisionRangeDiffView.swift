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
    @State private var filesChanges: [ExpandableModel<FileDiff>] = []

    var body: some View {
        ScrollView {
            FileDiffsView(expandableFileDiffs: $filesChanges)
                .padding()
        }
        .background(Color(NSColor.textBackgroundColor))
        .onChange(of: selectionLogID + subSelectionLogID, initial: true) { oldValue, newValue in
            Task {
                let raw = try await Process.output(
                    GitDiff(directory: folder!, noRenames: false, revisionRange: "\(subSelectionLogID)...\(selectionLogID)")
                    )
                filesChanges = try Diff(raw: raw).fileDiffs.map { .init(isExpanded: true, model: $0) }
            }
        }
    }
}
