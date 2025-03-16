//
//  StageFileDiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/16.
//

import SwiftUI

struct StageFileDiffView: View {
    @State var isExpanded: Bool
    var fileDiff: FileDiff
    var selectButtonImageSystemName: String
    var selectButtonHelp: String
    var onSelectFileDiff: ((FileDiff) -> Void)?
    var onSelectChunk: ((FileDiff, Chunk) -> Void)?

    var body: some View {
        Section(isExpanded: $isExpanded) {
            ForEach(fileDiff.chunks) { chunk in
                HStack {
                    ChunkView(chunk: chunk, filePath: fileDiff.toFilePath)
                    Spacer()
                    Button {
                        onSelectChunk?(fileDiff, chunk)
                    } label: {
                        Image(systemName: selectButtonImageSystemName)
                    }
                    .buttonStyle(.accessoryBar)
                    .help(selectButtonHelp)
                    .padding()
                }
                .padding(.horizontal)
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
                ExpandingButton(isExpanded: $isExpanded)
            }
                .padding()
                .background(Color(NSColor.textBackgroundColor).opacity(0.98))
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
        }
    }
}
