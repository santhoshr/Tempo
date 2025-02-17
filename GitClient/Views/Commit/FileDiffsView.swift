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
        LazyVStack(alignment: .leading) {
            ForEach(fileDiffs) { fileDiff in
                Text(fileDiff.header)
                    .fontWeight(.bold)
                ForEach(fileDiff.extendedHeaderLines, id: \.self) { line in
                    Text(line)
                        .fontWeight(.bold)
                }
                ForEach(fileDiff.fromFileToFileLines, id: \.self) { line in
                    Text(line)
                        .fontWeight(.bold)
                }
                chunksView(fileDiff.chunks, filePath: fileDiff.filePath)
                    .padding(.top, 8)
            }
        }
        .font(Font.system(.body, design: .monospaced))
    }

    private func chunksView(_ chunks: [Chunk], filePath: String) -> some View {
        ForEach(chunks) { chunk in
            ChunkView(chunk: chunk, filePath: filePath)
        }
    }
}
