//
//  CommitLogView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/03/02.
//

import SwiftUI

struct CommitLogView: View {
    @Environment(\.isRemoteRepositoryUpdating) var isRemoteUpdating: Bool
    var commitHash: String
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
    @State private var tags: [String] = []
    @State private var branches: [Branch] = []
    @State private var error: Error?

    var body: some View {   
        VStack(spacing: 0) {
            ScrollView {
                if !branches.isEmpty || !tags.isEmpty {
                    VStack {
                        if !branches.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 14) {
                                    ForEach(branches) { branch in
                                        Label(branch.name, systemImage: "arrow.triangle.branch")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        if !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 14) {
                                    ForEach(tags, id: \.self) { tag in
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
                        .font(Font.system(.body, design: .monospaced))
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
        .onChange(of: commitHash, initial: true, {
            Task {
                do {
                    gitShow = try await Process.output(GitShow(directory: folder.url, object: commitHash))
                    tags = try await Process.output(GitTagPointsAt(directory: folder.url, object: commitHash))
                    branches = try await Process.output(GitBranchPointsAt(directory: folder.url, object: commitHash))
                } catch {
                    self.error = error
                }
            }
        })
        .onChange(of: isRemoteUpdating, { oldValue, newValue in
            if oldValue && !newValue {
                Task {
                    do {
                        tags = try await Process.output(GitTagPointsAt(directory: folder.url, object: commitHash))
                        branches = try await Process.output(GitBranchPointsAt(directory: folder.url, object: commitHash))
                    } catch {
                        self.error = error
                    }
                }
            }
        })
        .errorAlert($error)
    }
}
