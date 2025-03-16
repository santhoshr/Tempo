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
        VStack(alignment: .leading) {
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
                StagedFileDiffView(fileDiffs: fileDiffs, onSelectFileDiff: onSelectFileDiff, onSelectChunk: onSelectChunk, selectChunkButtonImageSystemName: "minus.circle", selectChunkButtonHelp: "Unstage this hunk")
            } header: {
                SectionHeader(title: "Staged", isExpanded: $isExpanded)
            }
        }
    }
}
