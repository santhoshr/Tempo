//
//  FileDiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/16.
//

import SwiftUI

struct FileDiffView: View {
    @Binding var expandableFileDiff: ExpandableModel<FileDiff>
    var contextMenuFileNames: [String]? // Other files in the same commit
    var onNavigateToFile: ((String) -> Void)? // Navigation callback
    
    private func sanitizeFilePathForID(_ filePath: String) -> String {
        // Only escape truly problematic characters, keep path structure
        return filePath.replacingOccurrences(of: " ", with: "_")
    }

    var body: some View {
        DisclosureGroup(isExpanded: $expandableFileDiff.isExpanded) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                    chunksView(expandableFileDiff.model.chunks, filePath: expandableFileDiff.model.toFilePath)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            }
        } label: {
            FileNameView(
                toFilePath: expandableFileDiff.model.toFilePath, 
                filePathDisplay: expandableFileDiff.model.filePathDisplay,
                contextMenuFileNames: contextMenuFileNames,
                onNavigateToFile: onNavigateToFile
            )
            .padding(.leading, 3)
            .id("commit_file_header_\(expandableFileDiff.model.toFilePath)")
        }
    }

    private func chunksView(_ chunks: [Chunk], filePath: String) -> some View {
        ForEach(chunks) { chunk in
            ChunkView(chunk: chunk, filePath: filePath)
        }
    }
}
