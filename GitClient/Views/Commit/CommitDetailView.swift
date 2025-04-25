//
//  CommitDetailView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/08.
//

import SwiftUI

struct CommitDetailView: View {
    var commitHash: String
    var folder: Folder
    @State private var commit: Commit?
    @State private var error: Error?

    var body: some View {
        VStack {
            if let commit {
                CommitDetailContentView(commit: commit, folder: folder)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
        .task {
            do {
                commit = try await Process.output(GitShow(directory: folder.url, object: commitHash)).commit
            } catch {
                self.error = error
            }
        }
        .errorSheet($error)
    }
}
