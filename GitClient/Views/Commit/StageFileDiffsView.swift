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
    @State private var isExpanded = true

    var body: some View {
        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
            ForEach(fileDiffs) { fileDiff in
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
                            VStack {
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
                    }
                        .padding()
                        .background(Color(NSColor.textBackgroundColor).opacity(0.98))
                        .onTapGesture {
                            print("Hi")
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }
                }
            }
            .font(Font.system(.body, design: .monospaced))
        }
    }
}
