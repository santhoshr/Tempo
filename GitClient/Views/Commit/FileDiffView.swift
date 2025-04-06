//
//  FileDiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/16.
//

import SwiftUI

struct FileDiffView: View {
    @Binding var expandableFileDiff: ExpandableModel<FileDiff>
    var onSelectAllExpanded: ((Bool) -> Void)

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
            Section(isExpanded: $expandableFileDiff.isExpanded) {
                chunksView(expandableFileDiff.model.chunks, filePath: expandableFileDiff.model.toFilePath)
            } header: {
                FileDiffHeader(
                    isExpanded: $expandableFileDiff.isExpanded,
                    filePathDisplay: expandableFileDiff.model.filePathDisplay,
                    header: expandableFileDiff.model.header,
                    extendedHeaderLines: expandableFileDiff.model.extendedHeaderLines,
                    fromFileToFileLines: expandableFileDiff.model.fromFileToFileLines,
                    onSelectAllExpanded: onSelectAllExpanded
                )
            }
        }
    }

    private func chunksView(_ chunks: [Chunk], filePath: String) -> some View {
        ForEach(chunks) { chunk in
            ChunkView(chunk: chunk, filePath: filePath)
                .padding(.bottom)
        }
    }
}
