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
    var onNavigateToUnstagedChanges: (() -> Void)?
    var onNavigateToUntrackedFiles: (() -> Void)?
    var onNavigateToFile: ((String) -> Void)?
    var hasUntrackedFiles: Bool = false // Track if untracked files exist
    @State private var isExpanded = true
    
    private var contextMenuOptions: [SectionHeader.ContextMenuOption] {
        var options = [
            SectionHeader.ContextMenuOption(
                title: "Unstaged Changes", 
                systemImage: "minus.circle", 
                action: "unstaged"
            )
        ]
        
        // Only add "Untracked Files" option if there are untracked files
        if hasUntrackedFiles {
            options.append(
                SectionHeader.ContextMenuOption(
                    title: "Untracked Files", 
                    systemImage: "plus.circle", 
                    action: "untracked"
                )
            )
        }
        
        return options
    }

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
            } else {
                StagedFileDiffView(
                    expandableFileDiffs: $fileDiffs,
                    selectButtonImageSystemName: "minus.circle",
                    selectButtonHelp: "Unstage This Hunk",
                    onSelectFileDiff: onSelectFileDiff,
                    onSelectChunk: onSelectChunk,
                    contextMenuFileNames: fileDiffs.compactMap { $0.model.toFilePath },
                    onNavigateToFile: onNavigateToFile,
                    fileIDPrefix: "s"
                )
                .padding(.leading, 4)
                .padding(.top)
            }
        } label: {
            SectionHeader(
                title: "Staged Changes",
                contextMenuOptions: contextMenuOptions,
                onContextMenuAction: { action in
                    switch action {
                    case "unstaged":
                        onNavigateToUnstagedChanges?()
                    case "untracked":
                        onNavigateToUntrackedFiles?()
                    default:
                        break
                    }
                }
            )
            .padding(.leading, 3)
        }
        .id("staged_header")
        .padding(.horizontal)
    }
}
