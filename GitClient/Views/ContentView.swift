//
//  ContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI

struct ContentView: View {
    @State private var folders: [Folder] = []
    @State private var selectionFolderURL: URL?
    private var selectionFolder: Folder? {
        guard let selectionFolderURL = selectionFolderURL else { return nil}
        return folders.first(where: { $0.url == selectionFolderURL })
    }
    @State private var selectionLog: Log?
    @State private var folderIsRefresh = false
    @State private var error: Error?


    var body: some View {
        NavigationSplitView {
            List(folders, id: \.url, selection: $selectionFolderURL) {
                Text($0.displayName)
                    .help($0.url.path)
            }
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
                }
            }
        } content: {
            if let folder = selectionFolder {
                FolderView(folder: folder, selectionLog: $selectionLog, isRefresh: $folderIsRefresh)
            } else {
                Text("No Folder Selection")
                    .foregroundColor(.secondary)
            }
        } detail: {
            switch selectionLog {
            case .notCommitted(let string):
                DiffView(diff: string, folder: selectionFolder!) {
                    selectionLog = nil
                    folderIsRefresh = true
                }
            case .committed(let commit):
                Text(commit.hash)
            case nil:
                Text("No Selection")
            }
        }
        .frame(minWidth: 700, minHeight: 300)
        .onAppear {
            do {
                folders = try FolderStore.folders()
            } catch {
                self.error = error
            }
        }
        .onChange(of: selectionFolder, {
            selectionLog = nil
        })
        .errorAlert($error)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
