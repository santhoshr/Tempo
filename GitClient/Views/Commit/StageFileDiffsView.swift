//
//  StagedFileDiffsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/15.
//
import SwiftUI

struct StagedFileDiffView: View {
    @Binding var expandableFileDiffs: [ExpandableModel<FileDiff>]
    var selectButtonImageSystemName: String
    var selectButtonHelp: String
    var onSelectFileDiff: ((FileDiff) -> Void)?
    var onSelectChunk: ((FileDiff, Chunk) -> Void)?

    var body: some View {
        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
            ForEach($expandableFileDiffs, id: \.self) { $fileDiff in
                StageFileDiffView(
                    expandableFileDiff: $fileDiff,
                    selectButtonImageSystemName: selectButtonImageSystemName,
                    selectButtonHelp: selectButtonHelp,
                    onSelectExpandedAll: { isExpandedAll in
                        expandableFileDiffs = expandableFileDiffs.map { .init(isExpanded: isExpandedAll, model: $0.model) }
                    },
                    onSelectFileDiff: onSelectFileDiff,
                    onSelectChunk: onSelectChunk
                )
            }
            .font(Font.system(.body, design: .monospaced))
        }
    }
}
