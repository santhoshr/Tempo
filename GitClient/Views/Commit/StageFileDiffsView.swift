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
    var contextMenuFileNames: [String]? // Other files in the same commit
    var onNavigateToFile: ((String) -> Void)? // Navigation callback
    var fileIDPrefix: String = "file" // Prefix for file IDs
    @Environment(\.expandAllFiles) private var expandAllFilesID: UUID?
    @Environment(\.collapseAllFiles) private var collapseAllFilesID: UUID?
    

    var body: some View {
        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
            ForEach(Array($expandableFileDiffs.enumerated()), id: \.offset) { index, $fileDiff in
                StageFileDiffView(
                    expandableFileDiff: $fileDiff,
                    selectButtonImageSystemName: selectButtonImageSystemName,
                    selectButtonHelp: selectButtonHelp,
                    onSelectFileDiff: onSelectFileDiff,
                    onSelectChunk: onSelectChunk,
                    contextMenuFileNames: contextMenuFileNames,
                    onNavigateToFile: onNavigateToFile,
                    fileIndex: index + 1,
                    fileIDPrefix: fileIDPrefix
                )
                .id("\(fileIDPrefix)\(index + 1)")
            }
            .font(Font.system(.body, design: .monospaced))
        }
        .onChange(of: expandAllFilesID) { _, _ in
            expandableFileDiffs = expandableFileDiffs.map { ExpandableModel(isExpanded: true, model: $0.model)}
        }
        .onChange(of: collapseAllFilesID) { _, _ in
            expandableFileDiffs = expandableFileDiffs.map { ExpandableModel(isExpanded: false, model: $0.model)}
        }
    }
}
