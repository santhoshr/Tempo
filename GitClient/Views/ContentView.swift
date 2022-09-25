//
//  ContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI

struct ContentView: View {
    @State private var folders: [Folder] = []
    @State private var error: Error?

    var body: some View {
        NavigationView {
            List(folders, id: \.url) {
                FolderView(folder: $0)
                    .help($0.url.path)
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
            .onAppear {
                do {
                    folders = try FolderStore.folders()
                } catch {
                    self.error = error
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
