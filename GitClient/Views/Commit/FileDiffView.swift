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
                HStack {
                    Text(expandableFileDiff.model.filePathDisplay)
                        .fontWeight(.bold)
                        .help(expandableFileDiff.model.header + "\n" + (expandableFileDiff.model.extendedHeaderLines + expandableFileDiff.model.fromFileToFileLines).joined(separator: "\n"))
                        .font(Font.system(.body, design: .default))
                    Spacer()
                    ExpandingButton(
                        isExpanded: $expandableFileDiff.isExpanded,
                        onSelectExpandedAll: onSelectAllExpanded
                    )
                    .padding(.vertical)
                }
                .background(Color(NSColor.textBackgroundColor).opacity(0.98))
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
