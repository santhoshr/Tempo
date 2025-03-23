//
//  MergeCommitContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/13.
//

import SwiftUI

struct MergeCommitContentView: View {
    var mergeCommit: CommitDetail
    var directoryURL: URL
    @State private var commits: [Commit] = []
    @State private var filesChanged: [ExpandableModel<FileDiff>] = []
    @State private var error: Error?
    @State private var tab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CommitTabView(tab: $tab)
                .padding(.vertical)
            if tab == 0 {
                HStack(alignment: .top, spacing: 16) {
                    CommitsView(commits: commits)
                    Divider()
                        .frame(height: 44)
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "arrow.triangle.merge")
                            Text("2 parents")
                        }
                        HStack {
                            NavigationLink(mergeCommit.parentHashes[0].prefix(5), value: mergeCommit.parentHashes[0])
                            Text("+")
                            NavigationLink(mergeCommit.parentHashes[1].prefix(5), value: mergeCommit.parentHashes[1])
                        }
                    }
                    .buttonStyle(.link)
                }
                .padding(.top)
            }
            if tab == 1 {
                FileDiffsView(expandableFileDiffs: $filesChanged)
            }
        }
        .padding(.bottom)
        .task {
            do {
                commits = try await Array(Process.output(GitLog(directory: directoryURL, revisionRange: "\(mergeCommit.parentHashes[0])..\(mergeCommit.hash)")).dropFirst())
                let diffRaw = try await Process.output(
                    GitDiff(directory: directoryURL, noRenames: false, commitsRange: mergeCommit.parentHashes[0] + ".." + mergeCommit.hash)
                )
                filesChanged = try Diff(raw: diffRaw).fileDiffs.map { .init(isExpanded: true, model: $0) }
            } catch {
                self.error = error
            }
        }
        .errorAlert($error)
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
                authorDate: "1 seconds ago",
                title: "Hello world!",
                body: "body",
                branches: [],
                tags: [],
                diff: try! Diff(raw: "")),
            directoryURL: URL(string: "file:///maoyama/Projects/")!
        )
    }
}

struct CommitsView: View {
    var commits: [Commit]

    var body: some View {
        LazyVStack(spacing: 4) {
            ForEach(commits, id:\.self) { commit in
                NavigationLink(value: commit.hash) {
                    VStack (alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(commit.title)
                            Spacer()
                            Text(commit.hash.prefix(5))
                                .font(Font.system(.body, design: .rounded))
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
