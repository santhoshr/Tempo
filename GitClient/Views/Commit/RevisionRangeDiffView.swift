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
    @State private var revisionRangeText = ""

    var body: some View {
        ScrollView {
            FileDiffsView(expandableFileDiffs: $filesChanges)
                .padding()
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
                            print("Submit" + revisionRangeText)
                        }
                }
                Spacer()
            }
            .background(Color(nsColor: .textBackgroundColor))
            .frame(height: 40)
        })
        .onChange(of: selectionLogID + subSelectionLogID, initial: true) { oldValue, newValue in
            Task {
                revisionRangeText = subSelectionLogID.prefix(8) + "..." + selectionLogID.prefix(8)
                let raw = try await Process.output(
                    GitDiff(directory: folder!, noRenames: false, revisionRange: "\(subSelectionLogID)...\(selectionLogID)")
                    )
                filesChanges = try Diff(raw: raw).fileDiffs.map { .init(isExpanded: true, model: $0) }
            }
        }
    }
}
