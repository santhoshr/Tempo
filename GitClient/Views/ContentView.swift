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
    @State private var selectionLogID: String?
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
            if let selectionFolderURL = selectionFolderURL, let folder = folders.first(where: { $0.url == selectionFolderURL }) {
                FolderView(folder: folder, selectionLogID: $selectionLogID)
            } else {
                Text("No Folder Selection")
                    .foregroundColor(.secondary)
            }
        } detail: {
            Text(selectionLogID ?? "")
        }
        .frame(minWidth: 700, minHeight: 300)
        .onAppear {
            do {
                folders = try FolderStore.folders()
            } catch {
                self.error = error
            }
        }
        .errorAlert($error)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
