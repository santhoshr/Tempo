//
//  CommitsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import SwiftUI

struct FolderView: View {
    private var commits: [String: [Commit]] {
        [
            "GitClient": [Commit(message: "Commit"), Commit(message: "Commit 2"), Commit(message: "Commit 3")],
            "GitClient2": [Commit(message: "Commit2"), Commit(message: "Commit2 2"), Commit(message: "Commit2 3")],
            "GitClient3": [Commit(message: "Commit3"), Commit(message: "Commit3 2"), Commit(message: "Commit3 3")],
        ]
    }
    var folder: Folder
    @State private var error: Error?

    var body: some View {
        NavigationLink(folder.displayName) {
            List(commits[folder.displayName] ?? []) { commit in
                NavigationLink(commit.message) {
                    VStack {
                        Text(commit.message)
                        Text(commit.id)
                    }
                }
            }
            .onAppear {
                print("onAppear")
                do {
                    let r = try GitLog(directory: folder.url).run()
                    print(r)
                } catch {
                    self.error = error
                    print(error)
                }
            }
            .errorAlert($error)
            .navigationTitle(folder.displayName)
            .navigationSubtitle("main")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {

                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .help("Change Branch")
                }
            }
            .toolbar {
                Button {

                } label: {
                    Image(systemName: "arrow.down")
                }
                .help("Pull")
                Button {

                } label: {
                    Image(systemName: "arrow.up")
                }
                .help("Push")
            }
        }
    }
}

struct CommitsView_Previews: PreviewProvider {
    static var previews: some View {
        FolderView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!))
    }
}
