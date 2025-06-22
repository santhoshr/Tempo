//
//  FileDiffsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/04.
//

import SwiftUI

struct FileDiffsView: View {
    @Binding var expandableFileDiffs: [ExpandableModel<FileDiff>]
    @Environment(\.expandAllFiles) private var expandAllFilesID: UUID?
    @Environment(\.collapseAllFiles) private var collapseAllFilesID: UUID?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                Button {
                    expandableFileDiffs = expandableFileDiffs.map { ExpandableModel(isExpanded: true, model: $0.model)}
                } label: {
                    Image(systemName: "arrow.up.and.line.horizontal.and.arrow.down")
                }
                .help("Expand All Files")
                Button {
                    expandableFileDiffs = expandableFileDiffs.map { ExpandableModel(isExpanded: false, model: $0.model)}
                } label: {
                    Image(systemName: "arrow.down.and.line.horizontal.and.arrow.up")
                }
                .help("Collapse All Files")
            }
            .buttonStyle(.accessoryBar)

            ForEach($expandableFileDiffs, id: \.self) { $expandedFileDiff in
                FileDiffView(expandableFileDiff: $expandedFileDiff)
            }
            .padding(.top, 2)
            .onChange(of: expandAllFilesID) { _, _ in
                expandableFileDiffs = expandableFileDiffs.map { ExpandableModel(isExpanded: true, model: $0.model)}
            }
            .onChange(of: collapseAllFilesID) { _, _ in
                expandableFileDiffs = expandableFileDiffs.map { ExpandableModel(isExpanded: false, model: $0.model)}
            }
        }
        .font(Font.system(.body, design: .monospaced))
        .padding(.top, 6)
    }
}
