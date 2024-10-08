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
                chunksViews(fileDiff.chunks)
                    .padding(.top, 8)
            }
        }
    }

    // to be able to select multiple lines of text
    private func chunksViews(_ chunks: [Chunk]) -> Text {
        let views = chunks.map { chunk in
            let chunksText = chunk.lines.map { line in
                Text(line.raw)
                    .foregroundStyle(chunkLineColor(line))
            }
            return chunksText.reduce(Text("")) { partialResult, text in
                partialResult + text + Text("\n")
            }
        }
        return views.reduce(Text("")) { partialResult, text in
            partialResult + text + Text("\n")
        }
    }

    private func chunkLineColor(_ line: Chunk.Line) -> Color {
        switch line.kind {
        case .header:
            return .secondary
        case .removed:
            return .red
        case .added:
            return .green
        case .unchanged:
            return .primary
        }
    }
}
