//
//  CommitDetailStackView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/11.
//

import SwiftUI

struct CommitDetailStackView: View {
    @State private var path: [String] = []
    var commit: Commit
    var folder: Folder

    fileprivate func backButtonBar() -> some View {
        return HStack {
            Button {
                path = path.dropLast()
            } label: {
                Image(systemName: "chevron.backward")
            }
            .background(Color(NSColor.textBackgroundColor).opacity(1))
            .padding(.horizontal)
            .padding(.vertical, 8)
            Spacer()
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.98))
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            CommitDetailRootView(commit: commit, folder: folder)
                .navigationDestination(for: String.self) { commitHash in
                    CommitDetailView(commitHash: commitHash, folder: folder)
                        .safeAreaInset(edge: .top, spacing: 0, content: {
                            backButtonBar()
                        })
                }
                .navigationBarBackButtonHidden()
        }

    }
}
