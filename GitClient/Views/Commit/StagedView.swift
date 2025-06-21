//
//  StagedView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/07.
//

import SwiftUI

struct StagedView: View {
    @Binding var fileDiffs: [ExpandableModel<FileDiff>]
    var onSelectFileDiff: ((FileDiff) -> Void)?
    var onSelectChunk: ((FileDiff, Chunk) -> Void)?
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if fileDiffs.isEmpty {
                LazyVStack(alignment: .center) {
                    Label("No Changes", systemImage: "plusminus")
                        .foregroundStyle(.secondary)
                        .padding()
                        .padding()
                        .padding(.trailing)
                }
            }
            StagedFileDiffView(
                expandableFileDiffs: $fileDiffs,
                selectButtonImageSystemName: "minus.circle",
                selectButtonHelp: "Unstage This Hunk",
                onSelectFileDiff: onSelectFileDiff,
                onSelectChunk: onSelectChunk
            )
        } label: {
            SectionHeader(title: "Staged Changes")
        }
        .padding(.horizontal)
    }
}
