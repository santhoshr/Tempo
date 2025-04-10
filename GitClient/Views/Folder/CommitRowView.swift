//
//  CommitRowView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/10.
//

import SwiftUI

struct CommitRowView: View {
    var commit: Commit

    var body: some View {
        VStack (alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(commit.title)
                Spacer()
                Text(commit.hash.prefix(5))
                    .foregroundStyle(.tertiary)
                if commit.parentHashes.count == 2 {
                    Image(systemName: "arrow.triangle.merge")
                        .foregroundStyle(.tertiary)
                }
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
}
