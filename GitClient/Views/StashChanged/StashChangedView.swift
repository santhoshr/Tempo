//
//  StashChangedView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/14.
//

import SwiftUI

struct StashChangedView: View {
    var folder: Folder
    @Binding var showingStashChanged: Bool
    @State private var stashList: [Stash]?
    @State private var error: Error?
    var onNavigateToUncommitted: (() -> Void)?

    var body: some View {
        StashChangedContentView(folder: folder, showingStashChanged: $showingStashChanged, stashList: stashList, onTapDropButton: { stash in
            Task {
                do {
                    try await Process.output(GitStashDrop(directory: folder.url, index: stash.index))
                    stashList = try await Process.output(GitStashList(directory: folder.url))
                } catch {
                    self.error = error
                }
            }
        }, onStashApplied: {
            Task {
                do {
                    stashList = try await Process.output(GitStashList(directory: folder.url))
                } catch {
                    self.error = error
                }
            }
        }, onNavigateToUncommitted: onNavigateToUncommitted)
        .task {
            do {
               stashList = try await Process.output(GitStashList(directory: folder.url))
            } catch {
                self.error = error
            }
        }
        .errorSheet($error)
    }
}
