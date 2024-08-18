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
                    Text(branch.name)
                    Spacer()
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
        .errorAlert($error)
    }
}

struct BranchesView_Previews: PreviewProvider {
    static var previews: some View {
        BranchesView(
            folder: .init(url: .init(string: "file://hoge")!),
            onSelect: { _ in }, 
            onSelectMergeInto: { _ in },
            onSelectNewBranchFrom: { _ in }
        )
    }
}
