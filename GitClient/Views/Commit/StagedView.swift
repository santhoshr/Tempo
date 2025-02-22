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
    @State private var isExpanded = true

    var body: some View {
        LazyVStack(alignment: .leading, pinnedViews: .sectionHeaders) {
            Section (isExpanded: $isExpanded) {
                if fileDiffs.isEmpty {
                    LazyVStack(alignment: .center) {
                        Label("No Changed", systemImage: "plusminus")
                            .foregroundStyle(.secondary)
                            .padding()
                            .padding()
                            .padding(.trailing)
                    }
                }
                ForEach(fileDiffs) { fileDiff in
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
                .font(Font.system(.body, design: .monospaced))
            } header: {
                SectionHeader(title: "Staged", isExpanded: $isExpanded)
            }
        }
    }
}
