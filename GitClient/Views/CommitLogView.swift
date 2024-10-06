//
//  CommitLogView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/03/02.
//

import SwiftUI

struct CommitLogView: View {
    var commit: Commit
    var folder: Folder
    @State private var gitShow = ""
    private var showMedium: ShowMedium? {
        do {
            return try ShowMedium(raw: gitShow)
        } catch {
            print(error)
            return nil
        }
    }
    @State private var error: Error?

    var body: some View {   
        VStack(spacing: 0) {
            ScrollView {
                if !commit.branches.isEmpty || !commit.tags.isEmpty {
                    VStack {
                        if !commit.branches.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 14) {
                                    ForEach(commit.branches, id: \.self) { branch in
                                        Label(branch, systemImage: "arrow.triangle.branch")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        if !commit.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 14) {
                                    ForEach(commit.tags, id: \.self) { tag in
                                        Label(tag, systemImage: "tag")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                }
                if let model = showMedium {
                    GitShowMediumView(showMedium: model)
                        .textSelection(.enabled)
                        .padding()
                } else {
                    Text(gitShow)
                        .textSelection(.enabled)
                        .font(Font.system(.body, design: .monospaced))
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.textBackgroundColor))
        }
        .onChange(of: commit, initial: true, {
            Task {
                do {
                    gitShow = try await Process.output(GitShow(directory: folder.url, object: commit.hash))
                } catch {
                    self.error = error
                }
            }
        })
        .errorAlert($error)
    }
}
