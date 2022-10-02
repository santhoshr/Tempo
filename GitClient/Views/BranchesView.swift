//
//  BranchesView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/02.
//

import SwiftUI

struct BranchesView: View {
    var folder: Folder
    @State private var branches: [Branch] = []
    @State private var error: Error?

    var body: some View {
        List(branches, id: \.name) { branch in
            HStack {
                Text(branch.name)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Task {
                    do {
                        print(try await Process.stdout(
                            GitSwitch(directory: folder.url, branchName: branch.name)
                        ))
                    } catch {
                        self.error = error
                    }
                }
                print("hoge")
            }
        }
        .listStyle(.sidebar)
        .task {
            do {
                branches = try await Process.stdout(GitBranch(directory: folder.url))
            } catch {
                self.error = error
            }
        }
        .frame(width: 300, height: 660)
        .errorAlert($error)
    }
}

struct BranchesView_Previews: PreviewProvider {
    static var previews: some View {
        BranchesView(folder: .init(url: .init(string: "file:///projects/")!))
    }
}
