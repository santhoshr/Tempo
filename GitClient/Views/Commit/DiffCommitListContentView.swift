//
//  DiffCommitListContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/18.
//

import SwiftUI

struct DiffCommitListContentView: View {
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
