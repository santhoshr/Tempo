//
//  DiffCommitListView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/18.
//

import SwiftUI

struct DiffCommitListView: View {
    @Environment(\.openURL) private var openURL
    var commits: [Commit]
    private var authorEmails: [String] {
        commits.map { $0.authorEmail }
            .reduce(into: []) { result, item in
                if !result.contains(item) {
                    result.append(item)
                }
            }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            DiffCommitListContentView(commits: commits)
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
    }
}
