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
                Icon(size: .small, authorEmail: commit.authorEmail, authorInitial: commit.authorInitial)
                Text(commit.author)
                Spacer()
                Text(commit.authorDateRelative)
            }
            .lineLimit(1)
            .foregroundStyle(.tertiary)
        }
    }
}
