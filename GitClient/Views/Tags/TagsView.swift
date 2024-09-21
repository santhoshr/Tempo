//
//  TagsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/21.
//


import SwiftUI

struct TagsView: View {
    var folder: Folder
    @Binding var showingTags: Bool
    @State private var tags: [String]?
    @State private var error: Error?

    var body: some View {
        TagsContentView(folder: folder, showingTags: $showingTags, tags: tags, onTapDeleteButton: { tagname in
            Task {
                do {
                    try await Process.output(GitTagDelete(directory: folder.url, tagname: tagname))
                    tags = try await Process.output(GitTag(directory: folder.url))
                } catch {
                    self.error = error
                }
            }
        })
        .task {
            do {
                tags = try await Process.output(GitTag(directory: folder.url))
            } catch {
                self.error = error
            }
        }
        .errorAlert($error)
    }
}
