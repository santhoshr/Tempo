//
//  StagedFileDiffsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/15.
//
import SwiftUI

struct StagedFileDiffView: View {
    var fileDiffs: [FileDiff]
    var selectButtonImageSystemName: String
    var selectButtonHelp: String
    var onSelectFileDiff: ((FileDiff) -> Void)?
    var onSelectChunk: ((FileDiff, Chunk) -> Void)?
    @State private var isExpandedAll = true

    var body: some View {
        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
            ForEach(fileDiffs) { fileDiff in
                StageFileDiffView(
                    isExpanded: isExpandedAll,
                    fileDiff: fileDiff,
                    selectButtonImageSystemName: selectButtonImageSystemName,
                    selectButtonHelp: selectButtonHelp,
                    onSelectFileDiff: onSelectFileDiff,
                    onSelectChunk: onSelectChunk
                )
            }
            .font(Font.system(.body, design: .monospaced))
        }
    }
}
