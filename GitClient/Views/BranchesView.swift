//
//  BranchesView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/02.
//

import SwiftUI

struct BranchesView: View {
    var folder: Folder
    var branch: Branch?
    var isRemote = false
    var onSelect: ((Branch) -> Void)
    var onSelectMergeInto: ((Branch) -> Void)
    var onSelectNewBranchFrom: ((Branch) -> Void)
    var onSelectRenameBranch: ((Branch) -> Void)?
    @State private var branches: [Branch] = []
    @State private var error: Error?
    @State private var selectedBranch: Branch?
    @State private var filterText: String = ""
    @State private var isFetching = false
    private var filteredBranch: [Branch] {
        guard !filterText.isEmpty else { return branches }
        return branches.filter { $0.name.lowercased().contains(filterText.lowercased()) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease")
                TextField(text: $filterText) {
                    Text("Filter")
                }
                if isRemote {
                    if isFetching {
                        ProgressView()
                            .scaleEffect(0.4)
                            .frame(width: 29, height: 17)
                            .padding(.leading)
                    } else {
                        Button(action: {
                            Task {
                                do {
                                    isFetching = true
                                    defer { isFetching = false }
                                    try await Process.output(GitFetch(directory: folder.url))
                                    branches = try await Process.output(GitBranch(directory: folder.url, isRemote: isRemote))
                                } catch {
                                    self.error = error
                                }
                            }
                        }, label: {
                            Image(systemName: "arrow.down")

                        })
                        .padding(.leading)
                        .help("Fetch")
                    }
                }
            }
            .padding(.top, 4)
            .padding([.horizontal, .bottom])
            Divider()
                .background(.ultraThinMaterial)
            List(filteredBranch, id: \.name) { branch in
                HStack {
                    Label(branch.name, systemImage: "arrow.triangle.branch")
                    Spacer()
                    if branch.isCurrent {
                        Text("Current")
                            .foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(branch)
                }
                .contextMenu {
                    if let currentBranch = self.branch {
                        Button("Marge into \"\(currentBranch.name)\"") {
                            onSelectMergeInto(branch)
                        }
                    }
                    Button("New Branch from \"\(branch.name)\"") {
                        onSelectNewBranchFrom(branch)
                    }
                    Button("Copy \"\(branch.name)\"") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.declareTypes([.string], owner: nil)
                        pasteboard.setString(branch.name, forType: .string)
                    }
                    if !isRemote {
                        Button("Rename") {
                            onSelectRenameBranch?(branch)
                        }
                    }
                    if self.branch != branch {
                        Button("Delete") {
                            Task {
                                do {
                                    try await Process.output(GitBranchDelete(directory: folder.url, isRemote: isRemote, branchName: branch.name))
                                    branches = try await Process.output(GitBranch(directory: folder.url, isRemote: isRemote))
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .textFieldStyle(.roundedBorder)
        .task {
            do {
                branches = try await Process.output(GitBranch(directory: folder.url, isRemote: isRemote))
            } catch {
                self.error = error
            }
        }
        .errorSheet($error)
    }
}

struct BranchesView_Previews: PreviewProvider {
    static var previews: some View {
        BranchesView(
            folder: .init(url: .init(string: "file://hoge")!),
            onSelect: { _ in }, 
            onSelectMergeInto: { _ in },
            onSelectNewBranchFrom: { _ in },
            onSelectRenameBranch: { _ in }
        )
    }
}
