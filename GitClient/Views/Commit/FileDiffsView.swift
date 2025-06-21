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
            ForEach($expandableFileDiffs, id: \.self) { $expandedFileDiff in
                FileDiffView(
                    expandableFileDiff: $expandedFileDiff,
                    onSelectAllExpanded: { isExpanded in
                        expandableFileDiffs = expandableFileDiffs.map { .init(isExpanded: isExpanded, model: $0.model) }
                    }
                )
            }
        }
        .font(Font.system(.body, design: .monospaced))
        .padding(.vertical)
    }
}
