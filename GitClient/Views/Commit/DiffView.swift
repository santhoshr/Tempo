//
//  DiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/18.
//

import SwiftUI

struct DiffView: View {
    @Binding var commits: [Commit]
    @Binding var filesChanged: [ExpandableModel<FileDiff>]
    @State private var tab = 0
    var contextMenuFileNames: [String]? // Other files in the same commit
    var onNavigateToFile: ((String) -> Void)? // Navigation callback

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DiffTabView(tab: $tab)
                .padding(.top)
            if tab == 0 {
                DiffCommitListView(commits: commits)
                    .padding(.vertical)
            }
            if tab == 1 {
                FileDiffsView(
                    expandableFileDiffs: $filesChanged,
                    contextMenuFileNames: contextMenuFileNames,
                    onNavigateToFile: onNavigateToFile
                )
            }
        }
    }
}
