//
//  StagedFileDiffsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/15.
//
import SwiftUI

struct StagedFileDiffView: View {
    var fileDiff: FileDiff
    var onSelectFileDiff: ((FileDiff) -> Void)?
    var onSelectChunk: ((FileDiff, Chunk) -> Void)?

    var body: some View {
        LazyVStack(spacing: 0) {
            StageFileDiffHeaderView(fileDiff: fileDiff, onSelectFileDiff: onSelectFileDiff)
                .padding()

            ForEach(fileDiff.chunks) { chunk in
                HStack {
                    ChunkView(chunk: chunk, filePath: fileDiff.toFilePath)
                    Spacer()
                    Button {
                        onSelectChunk?(fileDiff, chunk)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .buttonStyle(.accessoryBar)
                    .help("Unstage this hunk")
                    .padding()
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
    }
}
