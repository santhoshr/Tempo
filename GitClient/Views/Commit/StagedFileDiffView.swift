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
    @State private var isExpanded = true

    var body: some View {
        Section(isExpanded: $isExpanded) {
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
        } header: {
            HStack {
                StageFileDiffHeaderView(fileDiff: fileDiff, onSelectFileDiff: onSelectFileDiff)
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
}
