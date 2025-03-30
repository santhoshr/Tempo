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
    @State private var commitDetail: CommitDetail?
    @State private var fileDiffs: [ExpandableModel<FileDiff>] = []
    @State private var mergedIn: Commit?
    @State private var error: Error?
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if let commitDetail {
                    if !commitDetail.commit.branches.isEmpty || !commitDetail.commit.tags.isEmpty {
                        VStack {
                            if !commitDetail.commit.branches.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 14) {
                                        ForEach(commitDetail.commit.branches, id: \.self) { branch in
                                            Label(branch, systemImage: "arrow.triangle.branch")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            if !commitDetail.commit.tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 14) {
                                        ForEach(commitDetail.commit.tags, id: \.self) { tag in
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
                                Text(commitDetail.commit.hash)
                                    .foregroundColor(.secondary)
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
                            Text(commitDetail.commit.title.trimmingCharacters(in: .whitespacesAndNewlines))
                                .font(.title)
                                .padding(.leading)
                                .padding(.vertical)
                            if !commitDetail.commit.body.isEmpty {
                                Text(commitDetail.commit.body.trimmingCharacters(in: .whitespacesAndNewlines))
                                    .font(.body)
                                    .padding(.leading)
                                    .padding(.bottom, 8)
                            }
                            HStack {
                                AsyncImage(url: URL.gravater(email: commitDetail.commit.authorEmail, size: 26*3)) { image in
                                    image.resizable()
                                } placeholder: {
                                    RoundedRectangle(cornerSize: .init(width: 6, height: 6), style: .circular)
                                        .foregroundStyle(.quinary)
                                }
                                    .frame(width: 26, height: 26)
                                    .clipShape(RoundedRectangle(cornerSize: .init(width: 6, height: 6), style: .circular))
                                    .onTapGesture {
                                        guard let url = URL.gravater(email: commitDetail.commit.authorEmail, size: 400) else { return }
                                        openURL(url)
                                    }
                                Text(commitDetail.commit.author)
                                Divider()
                                    .frame(height: 10)
                                Text(commitDetail.commit.authorEmail)
                                Spacer()
                                Text(commitDetail.commit.authorDate)
                            }
                            .padding(.top, 6)
                            .foregroundStyle(.secondary)
                            Divider()
                                .padding(.top)
                            if commitDetail.commit.parentHashes.count == 2 {
                                MergeCommitContentView(mergeCommit: commitDetail.commit, directoryURL: folder.url)
                            } else {
                                FileDiffsView(expandableFileDiffs: $fileDiffs)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, (!commitDetail.commit.branches.isEmpty || !commitDetail.commit.tags.isEmpty) ? 0 : 32)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.textBackgroundColor))
            .textSelection(.enabled)
        }
        .task {
            commitDetail = nil
            mergedIn = nil

            do {
                commitDetail = try await Process.output(GitShow(directory: folder.url, object: commitHash))
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
                        revisionRange: "\(mergeCommit.parentHashes[0])..\(mergeCommit.hash)"
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
        .onChange(of: commitDetail, { _, newValue in
            if let newValue {
                fileDiffs = newValue.diff.fileDiffs.map { .init(isExpanded: true, model: $0) }
            } else {
                fileDiffs = []
            }
        })
        .errorAlert($error)
    }
}
