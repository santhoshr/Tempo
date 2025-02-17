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
                    .padding()
                    ForEach(fileDiff.chunks) { chunk in
                        HStack {
                            ChunkView(chunk: chunk, fileDiffHeader: fileDiff.header)
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
                }
                .font(Font.system(.body, design: .monospaced))
            } header: {
                SectionHeader(title: "Staged", isExpanded: $isExpanded)
            }
        }
    }
}
