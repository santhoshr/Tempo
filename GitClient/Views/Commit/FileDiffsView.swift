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
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                    Section {
                        chunksView(fileDiff.chunks, filePath: fileDiff.toFilePath)
                    } header: {
                        HStack {
                            Text(fileDiff.filePathDisplay)
                                .fontWeight(.bold)
                                .help(fileDiff.header + "\n" + (fileDiff.extendedHeaderLines + fileDiff.fromFileToFileLines).joined(separator: "\n"))
                                .font(Font.system(.body, design: .default))
                            Spacer()
                        }
                            .padding(.vertical)
                            .background(Color(NSColor.textBackgroundColor).opacity(0.98))
                    }
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
