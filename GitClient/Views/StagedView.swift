//
//  StagedView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/07.
//

import SwiftUI

struct StagedView: View {
    var fileDiffs: [FileDiff]
    var onSelectFileDiff: ((FileDiff) -> Void)?
    var onSelectChunk: ((FileDiff, Chunk) -> Void)?

    var body: some View {
        LazyVStack(alignment: .leading, pinnedViews: .sectionHeaders) {
            Section {
                ForEach(fileDiffs) { fileDiff in
                    HStack {
                        VStack(alignment: .leading) {
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
                        }
                        Spacer()
                        if fileDiff.chunks.isEmpty {
                            Button {
                                onSelectFileDiff?(fileDiff)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.accessoryBar)
                            .help("Unstage this hunk")
                            .padding()
                        }
                    }

                    ForEach(fileDiff.chunks) { chunk in
                        HStack {
                            chunkView(chunk)
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

                    }
                }
                .font(Font.system(.body, design: .monospaced))
                .padding([.trailing, .bottom, .leading])
            } header: {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Staged")
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.vertical, 9)
                    .padding(.horizontal)
                }
                .textSelection(.disabled)
                .background(Color(nsColor: .textBackgroundColor))
            }
        }
    }

    private func chunkView(_ chunk: Chunk) -> some View {
        chunk.lines.map { line in
            Text(line.raw)
                .foregroundStyle(chunkLineColor(line))
        }
        .reduce(Text("")) { partialResult, text in
            partialResult + text + Text("\n")
        }
    }

    private func chunkLineColor(_ line: Chunk.Line) -> Color {
        switch line.kind {
        case .removed:
            return .red
        case .added:
            return .green
        case .unchanged:
            return .primary
        }
    }
}
