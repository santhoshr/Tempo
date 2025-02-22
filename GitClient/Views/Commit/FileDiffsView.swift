//
//  FileDiffsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/04.
//

import SwiftUI

struct FileDiffsView: View {
    var fileDiffs: [FileDiff]

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(fileDiffs) { fileDiff in
                LazyVStack(alignment: .leading, spacing: 0) {
                    Text(fileDiff.filePathDisplay)
                        .fontWeight(.bold)
                        .help(fileDiff.header + "\n" + (fileDiff.extendedHeaderLines + fileDiff.fromFileToFileLines).joined(separator: "\n"))
                        .font(Font.system(.body, design: .default))
                        .padding(.bottom)
                    chunksView(fileDiff.chunks, filePath: fileDiff.toFilePath)
                }
                .padding(.bottom)
            }
        }
        .font(Font.system(.body, design: .monospaced))
    }

    private func chunksView(_ chunks: [Chunk], filePath: String) -> some View {
        ForEach(chunks) { chunk in
            ChunkView(chunk: chunk, filePath: filePath)
                .padding(.bottom)
        }
    }
}
