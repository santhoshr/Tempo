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
    @State private var mergedIn: Commit?
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
                        .padding(.top, 32)
                    }
                    HStack {
                        VStack (alignment: .leading) {
                            HStack {
                                Text(commit.hash)
                                    .foregroundStyle(.orange)
                                    .font(Font.system(.body, design: .rounded))
                                if let mergedIn {
                                    Divider()
                                        .frame(height: 10)
                                    HStack(spacing: 4) {
                                        Text("Merged in")
                                            .foregroundStyle(.secondary)
                                        NavigationLink(mergedIn.hash.prefix(5), value: mergedIn.hash)
                                            .buttonStyle(.link)
                                    }
                                }
                            }
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
                            Divider()
                                .padding(.vertical)
                            if commit.abbreviatedParentHashes.count == 2 {
                                MergeCommitContentView(mergeCommit: commit)
                            } else {
                                FileDiffsView(fileDiffs: commit.diff.fileDiffs)
                                    .font(Font.system(.body, design: .monospaced))
                            }
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
                commit = nil
                mergedIn = nil

                do {
                    commit = try await Process.output(GitShow(directory: folder.url, object: commitHash))
                    let mergeCommit = try await Process.output(GitLog(
                        directory: folder.url,
                        merges: true,
                        ancestryPath: true,
                        reverse: true,
                        revisionRange: "\(commitHash)..HEAD"
                    )).first
                    if let mergeCommit {
                        let mergedInCommits = try await Process.output(GitLog(
                            directory: folder.url,
                            revisionRange: "\(mergeCommit.abbreviatedParentHashes[0])..\(mergeCommit.hash)"
                        ))
                        let contains = mergedInCommits.contains { $0.hash == commitHash }
                        if contains  {
                            mergedIn = mergeCommit
                        }
                    }
                } catch {
                    self.error = error
                }
            }
        })
        .errorAlert($error)
    }
}
