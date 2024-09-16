//
//  StashChangedDetailView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/15.
//

import SwiftUI

struct StashChangedDetailView: View {
    var index: Int
    var folder: Folder
    @State private var diff = ""
    @State private var error: Error?

    var body: some View {
        StashChangedDetailContentView(diff: diff)
            .task {
                do {
                    diff = try await Process.output(GitStashShowDiff(directory: folder.url, index: index))
                } catch {
                    self.error = error
                }
            }
            .errorAlert($error)
    }
}
