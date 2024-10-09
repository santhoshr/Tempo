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
    @State private var commit: CommitDetail?
    @State private var error: Error?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if let commit {
                    if !commit.branches.isEmpty || !commit.tags.isEmpty {
                        VStack {
                            if !commit.branches.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 14) {
                                        ForEach(commit.branches, id: \.self) { branch in
                                            Label(branch, systemImage: "arrow.triangle.branch")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            if !commit.tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 14) {
                                        ForEach(commit.tags, id: \.self) { tag in
                                            Label(tag, systemImage: "tag")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top)
                        .padding(.top)
                    }
                    HStack {
                        VStack (alignment: .leading) {
                            Text(commit.hash)
                                .foregroundStyle(.orange)
                                .font(Font.system(.body, design: .rounded))
                            Text(commit.title.trimmingCharacters(in: .whitespacesAndNewlines))
                                .font(.title)
                                .padding(.leading)
                                .padding(.vertical)
                            if !commit.body.isEmpty {
                                Text(commit.body.trimmingCharacters(in: .whitespacesAndNewlines))
                                    .font(.body)
                                    .padding(.leading)
                                    .padding(.bottom, 8)
                            }
                            HStack {
                                Text(commit.author)
                                Divider()
                                    .frame(height: 10)
                                Text(commit.authorEmail)
                                Spacer()
                                Text(commit.authorDate)
                            }
                            .padding(.top, 6)
                            .foregroundStyle(.secondary)
                            if commit.abbreviatedParentHashes.count == 2 {
                                Label("2 parents " + commit.abbreviatedParentHashes[0] + " + " + commit.abbreviatedParentHashes[1], systemImage: "arrow.triangle.merge")
                                    .padding(.top)
                            }
                            FileDiffsView(fileDiffs: commit.diff.fileDiffs)
                                .font(Font.system(.body, design: .monospaced))
                                .padding(.top)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, (!commit.branches.isEmpty || !commit.tags.isEmpty) ? 0 : 32)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.textBackgroundColor))
            .textSelection(.enabled)
        }
        .onChange(of: commitHash, initial: true, {
            Task {
                do {
                    commit = try await Process.output(GitShow(directory: folder.url, object: commitHash))
                } catch {
                    self.error = error
                }
            }
        })
        .errorAlert($error)
    }
}
