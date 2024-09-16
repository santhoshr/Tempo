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
    @State var stashList: [Stash]?
    @State private var error: Error?

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
        })
        .task {
            do {
               stashList = try await Process.output(GitStashList(directory: folder.url))
            } catch {
                self.error = error
            }
        }
        .errorAlert($error)
    }
}
