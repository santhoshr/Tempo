//
//  ContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI

struct ContentView: View {
    @State private var folders: [Folder]
    @State private var error: Error?

    private var commits = [
        "GitClient": [Commit(message: "Commit"), Commit(message: "Commit 2"), Commit(message: "Commit 3")],
        "GitClient2": [Commit(message: "Commit2"), Commit(message: "Commit2 2"), Commit(message: "Commit2 3")],
        "GitClient3": [Commit(message: "Commit3"), Commit(message: "Commit3 2"), Commit(message: "Commit3 3")],
    ]

    init() {
        do {
            _folders = .init(wrappedValue: try FolderStore.folders())
        } catch {
            _folders = .init(wrappedValue: [])
            _error = .init(wrappedValue: GenericError(errorDescription: "Hi"))
        }
    }

    fileprivate func folderView(_ folder: Folder) -> NavigationLink<Text, some View> {
        return NavigationLink(folder.displayName) {
            List(commits[folder.displayName] ?? []) { commit in
                NavigationLink(commit.message) {
                    VStack {
                        Text(commit.message)
                        Text(commit.id)
                    }
                }
            }
            .navigationTitle(folder.url.absoluteString)
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

    var body: some View {
        NavigationView {
            List(folders, id: \.url) {
                folderView($0)
            }
            .listStyle(.sidebar)
            .navigationTitle("Folders")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.canCreateDirectories = false
                        panel.begin { (response) in
                            if response == .OK {
                                for fileURL in panel.urls {
                                    let chooseFolder = Folder(url: fileURL)
                                    folders.removeAll { $0 == chooseFolder }
                                    folders.insert(chooseFolder, at: 0)
                                    do {
                                        try FolderStore.save(folders)
                                    } catch {
                                        self.error = error
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "plus.rectangle.on.folder")
                    }
                    .help("Add project folder")
                    Button {
                        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                    } label: {
                        Image(systemName: "sidebar.leading")
                    }
                    .help("Hide or show the Navigator")
                }
            }
            .errorAlert($error)

            Text("No Folder Selection")
                .foregroundColor(.secondary)
            Text("")
        }
        .frame(minWidth: 700, minHeight: 300)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
