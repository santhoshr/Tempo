//
//  MergeCommitContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/13.
//

import SwiftUI

struct MergeCommitContentView: View {
    var mergeCommit: Commit
    var directoryURL: URL
    @State private var commits: [Commit] = []
    @State private var filesChanged: [ExpandableModel<FileDiff>] = []
    @State private var error: Error?
    @State private var tab = 0
    private var authorEmails: [String] {
        commits.map { $0.authorEmail }
            .reduce(into: []) { result, item in
                if !result.contains(item) {
                    result.append(item)
                }
            }
    }
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CommitTabView(tab: $tab)
                .padding(.vertical)
            if tab == 0 {
                HStack(alignment: .top, spacing: 24) {
                    CommitsView(commits: commits)
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 6) {
                            if commits.count > 1 {
                                Text("\(commits.count) commits")
                                Text(commits.first!.authorDateDisplayShort)
                                Image(systemName: "minus")
                                    .rotationEffect(.init(degrees: 90))
                                    .foregroundStyle(.tertiary)
                                Text(commits.last!.authorDateDisplayShort)
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
                                    ForEach(authorEmails, id: \.self) { email in
                                        AsyncImage(url: URL.gravater(email: email, size: 26*3)) { image in
                                            image.resizable()
                                        } placeholder: {
                                            RoundedRectangle(cornerSize: .init(width: 6, height: 6), style: .circular)
                                                .foregroundStyle(.quinary)
                                        }
                                            .frame(width: 26, height: 26)
                                            .clipShape(RoundedRectangle(cornerSize: .init(width: 6, height: 6), style: .circular))
                                            .onTapGesture {
                                                guard let url = URL.gravater(email: email, size: 400) else { return }
                                                openURL(url)
                                            }
                                    }
                                }
                                .padding(.vertical, 8)
                            } else {
                                EmptyView()
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(width: 120)
                }
                .padding(.top)
            }
            if tab == 1 {
                FileDiffsView(expandableFileDiffs: $filesChanged)
            }
        }
        .padding(.bottom)
        .onChange(of: mergeCommit, initial: true) {
            Task {
                do {
                    commits = try await Array(Process.output(GitLog(directory: directoryURL, revisionRange: "\(mergeCommit.parentHashes[0])..\(mergeCommit.hash)")).dropFirst())
                    let diffRaw = try await Process.output(
                        GitDiff(directory: directoryURL, noRenames: false, revisionRange: mergeCommit.parentHashes[0] + ".." + mergeCommit.hash)
                    )
                    filesChanged = try Diff(raw: diffRaw).fileDiffs.map { .init(isExpanded: true, model: $0) }
                } catch {
                    self.error = error
                }
            }
        }
        .errorSheet($error)
    }
}

#Preview {
    ScrollView {
        MergeCommitContentView(
            mergeCommit: .init(
                hash: "11fff",
                parentHashes: ["21fff", "31fff"],
                author: "maoyama",
                authorEmail: "a@aoyama.dev",
                authorDate: "2014-10-10T13:50:40+09:00",
                title: "Hello world!",
                body: "body",
                branches: [],
                tags: []
            ),
            directoryURL: URL(string: "file:///maoyama/Projects/")!
        )
    }
}

struct CommitsView: View {
    var commits: [Commit]

    var body: some View {
        LazyVStack(spacing: 4) {
            ForEach(commits) { commit in
                NavigationLink(value: commit.hash) {
                    VStack (alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(commit.title)
                                if !commit.body.isEmpty {
                                    Text(commit.body.trimmingCharacters(in: .whitespacesAndNewlines))
                                        .foregroundStyle(.secondary)
                                        .font(.callout)
                                }
                            }
                            Spacer()
                            Text(commit.hash.prefix(5))
                                .foregroundStyle(.tertiary)
                        }
                        HStack {
                            AsyncImage(url: URL.gravater(email: commit.authorEmail, size: 14*3)) { image in
                                image.resizable()
                            } placeholder: {
                                RoundedRectangle(cornerSize: .init(width: 3, height: 3), style: .circular)
                                    .foregroundStyle(.quinary)
                            }
                                .frame(width: 14, height: 14)
                                .clipShape(RoundedRectangle(cornerSize: .init(width: 3, height: 3), style: .circular))
                            Text(commit.author)
                            Spacer()
                            Text(commit.authorDateRelative)
                        }
                        .lineLimit(1)
                        .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                if commits.last != commit {
                    Divider()
                }
            }
            .accentColor(.primary)
        }
    }
}

struct CommitTabView: View {
    @Binding var tab: Int

    var body: some View {
        HStack {
            Spacer()
            Picker("", selection: $tab) {
                Text("Commits").tag(0)
                Text("Files Changed").tag(1)
            }
            .frame(maxWidth:400)
            .pickerStyle(.segmented)
            Spacer()
        }

    }
}
