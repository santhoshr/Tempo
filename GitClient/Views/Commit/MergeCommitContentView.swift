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
    @State private var filesChanged: Diff?
    @State private var error: Error?
    @State private var tab = 0

    var body: some View {
        VStack(alignment: .leading) {
            CommitTabView(tab: $tab)
                .padding(.bottom)
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
            }
            if tab == 1, let fileDiffs = filesChanged?.fileDiffs {
                FileDiffsView(fileDiffs: fileDiffs)
            }
        }
        .padding(.bottom)
        .onChange(of: mergeCommit, initial: true) { _, _ in
            Task {
                do {
                    commits = try await Array(Process.output(GitLog(directory: directoryURL, revisionRange: "\(mergeCommit.parentHashes[0])..\(mergeCommit.hash)")).dropFirst())
                    let diffRaw = try await Process.output(
                        GitDiff(directory: directoryURL, noRenames: false, commitsRange: mergeCommit.parentHashes[0] + ".." + mergeCommit.hash)
                    )
                    filesChanged = try Diff(raw: diffRaw)
                } catch {
                    self.error = error
                }
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
            ForEach(commits) { commit in
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
                                Circle()
                            }
                                .frame(width: 14, height: 14)
                                .clipShape(Circle())
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
            Button {
                tab = 0
            } label: {
                Image(systemName: "circle.circle")
                Text("Commits")
            }
            .disabled(tab == 0)
            Divider()
            Button {
                tab = 1
            } label: {
                Image(systemName: "plusminus")
                Text("Files Changed")
            }
            .disabled(tab == 1)
        }.buttonStyle(.borderless)
    }
}
