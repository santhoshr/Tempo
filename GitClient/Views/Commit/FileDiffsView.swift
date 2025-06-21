//
//  FileDiffsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/04.
//

import SwiftUI

struct FileDiffsView: View {
    @Binding var expandableFileDiffs: [ExpandableModel<FileDiff>]

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
                FileDiffView(
                    expandableFileDiff: $expandedFileDiff,
                    onSelectAllExpanded: { isExpanded in
                        expandableFileDiffs = expandableFileDiffs.map { .init(isExpanded: isExpanded, model: $0.model) }
                    }
                )
            }
            .padding(.top, 2)
        }
        .font(Font.system(.body, design: .monospaced))
        .padding(.top, 6)
    }
}
