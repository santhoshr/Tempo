//
//  CommitDetailContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/03/26.
//

import SwiftUI

struct CommitDetailContentView: View {
    var commit: Commit
    var folder: Folder
    @State private var commitDetail: CommitDetail?
    @State private var shortstat = ""
    @State private var fileDiffs: [ExpandableModel<FileDiff>] = []
    @State private var mergedIn: Commit?
    @State private var error: Error?
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Text(commit.hash.prefix(10))
                            .textSelection(.disabled)
                            .help("Commit Hash: " + commit.hash)
                            .contextMenu {
                                Button("Copy " + commit.hash) {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.declareTypes([.string], owner: nil)
                                    pasteboard.setString(commit.hash, forType: .string)
                                }
                            }
                        Image(systemName: "arrow.left")
                        NavigationLink(commit.parentHashes[0].prefix(5), value: commit.parentHashes[0])
                            .foregroundColor(.accentColor)
                        if commit.parentHashes.count == 2 {
                            Image(systemName: "plus")
                            NavigationLink(commit.parentHashes[1].prefix(5), value: commit.parentHashes[1])
                                .foregroundColor(.accentColor)
                        }
                        if let mergedIn {
                            Divider()
                                .frame(height: 10)
                            HStack(spacing: 4) {
                                Text("Merged in")
                                NavigationLink(mergedIn.hash.prefix(5), value: mergedIn.hash)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        if !commit.tags.isEmpty {
                            Divider()
                                .frame(height: 10)
                            HStack(spacing: 14) {
                                ForEach(commit.tags, id: \.self) { tag in
                                    Label(tag, systemImage: "tag")
                                }
                            }
                        }
                        if !commit.branches.isEmpty {
                            Divider()
                                .frame(height: 10)
                            HStack(spacing: 14) {
                                ForEach(commit.branches, id: \.self) { branch in
                                    Label(branch, systemImage: "arrow.triangle.branch")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .foregroundColor(.secondary)
                    .buttonStyle(.link)
                }
                .padding(.top)
                .padding(.top)
                .padding(.horizontal)
                HStack {
                    VStack (alignment: .leading) {
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
                            AsyncImage(url: URL.gravater(email: commit.authorEmail, size: 26*3)) { image in
                                image.resizable()
                            } placeholder: {
                                RoundedRectangle(cornerSize: .init(width: 6, height: 6), style: .circular)
                                    .foregroundStyle(.quinary)
                            }
                                .frame(width: 26, height: 26)
                                .clipShape(RoundedRectangle(cornerSize: .init(width: 6, height: 6), style: .circular))
                                .onTapGesture {
                                    guard let url = URL.gravater(email: commit.authorEmail, size: 400) else { return }
                                    openURL(url)
                                }
                            Text(commit.author)
                            Divider()
                                .frame(height: 10)
                            Text(commit.authorEmail)
                            Spacer()
                            Text(commit.authorDateDisplay)
                        }
                        .padding(.top)
                        .padding(.top, 8)
                        .foregroundStyle(.secondary)
                        Divider()
                            .padding(.top)
                        Text(shortstat)
                            .padding(.vertical, 6)
                        Divider()
                        if commit.parentHashes.count == 2 {
                            MergeCommitContentView(mergeCommit: commit, directoryURL: folder.url)
                        } else {
                            FileDiffsView(expandableFileDiffs: $fileDiffs)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.textBackgroundColor))
            .textSelection(.enabled)
        }
        .onChange(of: commit, initial: true, { _, commit in
            Task {
                do {
                    commitDetail = try await Process.output(GitShow(directory: folder.url, object: commit.hash))
                    let mergeCommit = try await Process.output(GitLog(
                        directory: folder.url,
                        merges: true,
                        ancestryPath: true,
                        reverse: true,
                        revisionRange: "\(commit.hash)..HEAD"
                    )).first
                    if let mergeCommit {
                        let mergedInCommits = try await Process.output(GitLog(
                            directory: folder.url,
                            revisionRange: "\(mergeCommit.parentHashes[0])..\(mergeCommit.hash)"
                        ))
                        let contains = mergedInCommits.contains { $0.hash == commit.hash }
                        if contains  {
                            mergedIn = mergeCommit
                        } else {
                            mergedIn = nil
                        }
                    } else {
                        mergedIn = nil
                    }
                } catch {
                    commitDetail = nil
                    mergedIn = nil
                    self.error = error
                }
            }
        })
        .onChange(of: commitDetail, { _, newValue in
            if let newValue {
                fileDiffs = newValue.diff.fileDiffs.map { .init(isExpanded: true, model: $0) }
            } else {
                fileDiffs = []
            }
        })
        .onChange(of: commit, initial: true, { _, commit in
            Task {
                shortstat = (try? await Process.output(GitShowShortstat(directory: folder.url, object: commit.hash))) ?? ""
            }
        })
        .errorSheet($error)
    }
}
