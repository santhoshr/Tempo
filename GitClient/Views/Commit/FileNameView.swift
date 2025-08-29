//
//  FileNameView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/06.
//

import SwiftUI

// Helper structures for hierarchical folder menu
class FolderNode {
    let name: String
    let fullPath: String
    var children: [String: FolderNode]
    var files: [FileItem]
    
    init(name: String, fullPath: String, children: [String: FolderNode], files: [FileItem]) {
        self.name = name
        self.fullPath = fullPath
        self.children = children
        self.files = files
    }
}

struct FileItem {
    let name: String
    let fullPath: String
}

struct FileNameView: View {
    @Environment(\.folder) private var current

    var toFilePath: String
    var filePathDisplay: String
    var contextMenuFileNames: [String]? // Other committed file names to show in context menu
    var onNavigateToFile: ((String) -> Void)? // Navigation callback
    
    var fileURL: URL? {
        current?.appending(path: toFilePath)
    }
    
    // Build hierarchical folder structure for context menu
    private var folderStructure: FolderNode {
        guard let contextMenuFileNames else { return FolderNode(name: "", fullPath: "", children: [:], files: []) }
        
        var rootNode = FolderNode(name: "", fullPath: "", children: [:], files: [])
        
        for filePath in contextMenuFileNames {
            let pathComponents = filePath.split(separator: "/").map(String.init)
            var currentNode = rootNode
            
            for (index, component) in pathComponents.enumerated() {
                let isFile = (index == pathComponents.count - 1)
                let currentPath = pathComponents[0...index].joined(separator: "/")
                
                if isFile {
                    currentNode.files.append(FileItem(name: component, fullPath: filePath))
                } else {
                    if currentNode.children[component] == nil {
                        currentNode.children[component] = FolderNode(name: component, fullPath: currentPath, children: [:], files: [])
                    }
                    currentNode = currentNode.children[component]!
                }
            }
        }
        
        return rootNode
    }
    
    // Build context menu recursively
    @ViewBuilder
    private func buildContextMenu(from node: FolderNode) -> some View {
        // Show files in the current folder (root files show directly)
        ForEach(node.files, id: \.fullPath) { file in
            Button(action: {
                onNavigateToFile?(file.fullPath)
            }) {
                Label(file.name, systemImage: "doc.text")
            }
            .disabled(file.fullPath == toFilePath) // Grey out current file
        }
        
        // Show subfolders as menus (root folders show directly)
        ForEach(Array(node.children.keys).sorted(), id: \.self) { folderName in
            if let childNode = node.children[folderName] {
                Menu {
                    buildSubMenu(from: childNode)
                } label: {
                    Label(folderName, systemImage: "folder")
                }
            }
        }
    }
    
    // Helper function for building submenu content
    @ViewBuilder
    private func buildSubMenu(from node: FolderNode) -> some View {
        // Show files in the current folder
        ForEach(node.files, id: \.fullPath) { file in
            Button(action: {
                onNavigateToFile?(file.fullPath)
            }) {
                Label(file.name, systemImage: "doc.text")
            }
            .disabled(file.fullPath == toFilePath) // Grey out current file
        }
        
        // Show subfolders as menus
        ForEach(Array(node.children.keys).sorted(), id: \.self) { folderName in
            if let childNode = node.children[folderName] {
                Menu {
                    buildSubMenu(from: childNode)
                } label: {
                    Label(folderName, systemImage: "folder")
                }
            }
        }
    }

    var body: some View {
        HStack {
            if let asset = Language.assetName(filePath: toFilePath) {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18)
            } else {
                Image(systemName: "doc")
                    .frame(width: 18, height: 18)
                    .fontWeight(.heavy)
            }
            Menu {
                // Left-click: Flat menu
                if let contextMenuFileNames, !contextMenuFileNames.isEmpty {
                    ForEach(contextMenuFileNames, id: \.self) { fileName in
                        Button(action: {
                            onNavigateToFile?(fileName)
                        }) {
                            Label(fileName, systemImage: "doc.text")
                        }
                        .disabled(fileName == toFilePath) // Grey out current file
                    }
                } else {
                    Text("No other files in this commit")
                        .foregroundStyle(.secondary)
                }
            } label: {
                Text(filePathDisplay)
                    .fontWeight(.bold)
                    .font(Font.system(.body, design: .default))
                    .foregroundColor(.primary)
            }
            .menuStyle(.borderlessButton)
            .disabled(contextMenuFileNames?.isEmpty != false)
            .contextMenu {
                // Right-click: Hierarchical menu
                if contextMenuFileNames?.isEmpty != false {
                    Text("No other files in this commit")
                        .foregroundStyle(.secondary)
                } else {
                    buildContextMenu(from: folderStructure)
                }
            }
            Button(action: {
                NSWorkspace.shared.open(fileURL!)
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.secondary)
                    .help("Open " + (fileURL?.absoluteString ?? ""))
            }
            .buttonStyle(.accessoryBar)
            Spacer()
        }
    }
}

#Preview {

    FileNameView(
        toFilePath: "Sources/MyFeature/File.swift",
        filePathDisplay: "Sources/MyFeature/File.swift",
        contextMenuFileNames: [
            "Sources/MyFeature/Other.swift", 
            "Sources/AnotherFeature/Helper.swift",
            "Tests/MyFeatureTests.swift",
            "Tests/Helpers/TestUtilities.swift",
            "README.md",
            "Package.swift"
        ],
        onNavigateToFile: { fileName in
            print("Navigate to: \(fileName)")
        }
    )
    FileNameView(
        toFilePath: "Sources/MyFeature/File.py",
        filePathDisplay: "Sources/MyFeature/File.py"
    )
    FileNameView(
        toFilePath: "Sources/MyFeature/File.rb",
        filePathDisplay: "Sources/MyFeature/File.rb"
    )
    FileNameView(
        toFilePath: "Sources/MyFeature/File.rs",
        filePathDisplay: "Sources/MyFeature/File.rs"
    )

    FileNameView(
        toFilePath: "Sources/MyFeature/File.js",
        filePathDisplay: "Sources/MyFeature/File.js"
    )

    FileNameView(
        toFilePath: "Sources/MyFeature/File.ml",
        filePathDisplay: "Sources/MyFeature/File.ml"
    )
    FileNameView(
        toFilePath: "Sources/MyFeature/File.pbj",
        filePathDisplay: "Sources/MyFeature/File.pbj"
    )
}
