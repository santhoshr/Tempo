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
            folders = try FolderStore.folders()
        } catch {
            folders = []
            self.error = error
        }
    }

    fileprivate func folderView(_ folder: Folder) -> NavigationLink<Text, some View> {
        return NavigationLink(folder.displayName) {
            List(commits[folder.path] ?? []) { commit in
                NavigationLink(commit.message) {
                    VStack {
                        Text(commit.message)
                        Text(commit.id)
                    }
                }
            }
            .navigationTitle(folder.path)
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
            VStack(alignment: .leading, spacing: 0) {
                List(folders, id: \.path) {
                    folderView($0)
                }
                .listStyle(.sidebar)
            }
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
                                    folders.insert(.init(path: fileURL.absoluteString), at: 0)
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

            Text("No Folder Selection")
                .foregroundColor(.secondary)
            Text("")
        }
        .frame(minWidth: 700, minHeight: 300)
        .errorAlert($error)
    }
}

extension View {
    func errorAlert(_ error: Binding<Error?>) -> some View {
        alert(
            error.wrappedValue?.localizedDescription ?? "",
            isPresented: .constant(error.wrappedValue != nil)) {
            Button("OK", role: .cancel) {
                error.wrappedValue = nil
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
