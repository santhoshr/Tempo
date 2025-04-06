//
//  StageFileDiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/16.
//

import SwiftUI

struct StageFileDiffView: View {
    @Binding var expandableFileDiff: ExpandableModel<FileDiff>
    var fileDiff: FileDiff {
        expandableFileDiff.model
    }
    var selectButtonImageSystemName: String
    var selectButtonHelp: String
    var onSelectExpandedAll: (Bool) -> Void
    var onSelectFileDiff: ((FileDiff) -> Void)?
    var onSelectChunk: ((FileDiff, Chunk) -> Void)?

    var body: some View {
        Section(isExpanded: $expandableFileDiff.isExpanded) {
            ForEach(fileDiff.chunks) { chunk in
                HStack(spacing: 0) {
                    ChunkView(chunk: chunk, filePath: fileDiff.toFilePath)
                    Spacer(minLength: 0)
                    Button {
                        onSelectChunk?(fileDiff, chunk)
                    } label: {
                        Image(systemName: selectButtonImageSystemName)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.accessoryBar)
                    .help(selectButtonHelp)
                    .padding(.vertical)
                    .padding(.trailing)
                }
                .padding(.leading)
            }
            .padding(.bottom)
            if fileDiff.chunks.isEmpty {
                HStack {
                    VStack(alignment: .leading) {
                        Text(fileDiff.header)
                        Text(fileDiff.extendedHeaderLines.joined(separator: "\n"))
                        Text(fileDiff.fromFileToFileLines.joined(separator: "\n"))
                    }
                    Spacer()
                    Button {
                        onSelectFileDiff?(fileDiff)
                    } label: {
                        Image(systemName: selectButtonImageSystemName)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.accessoryBar)
                    .help(selectButtonHelp)
                    .padding()
                }
                .padding(.horizontal)
            }
        } header: {
            HStack {
                StageFileDiffHeaderView(fileDiff: fileDiff)
                Spacer()
                ExpandingButton(
                    isExpanded: $expandableFileDiff.isExpanded,
                    onSelectExpandedAll: onSelectExpandedAll
                )
            }
                .padding()
                .background(Color(NSColor.textBackgroundColor).opacity(0.98))
        }
    }
}
