//
//  TagsContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/21.
//

import SwiftUI

struct TagsContentView: View {
    var folder: Folder
    @Binding var showingTags: Bool
    var tags: [String]?
    var onSelect: ((String) -> Void)?
    var onTapDeleteButton: ((String) -> Void)?
    @State private var selection: String?
    @State private var error: Error?

    var body: some View {
        if let tags {
            if tags.isEmpty {
                VStack {
                    Text("No Content")
                        .foregroundStyle(.secondary)
                }
            } else {
                List(tags, id: \.self, selection: $selection) { tag in
                    Text(tag)
                        .contextMenu {
                            Button("Delete") {
                                Task {
                                    do {
                                        try await Process.output(GitTagDelete(directory: folder.url, tagname: tag))
                                        showingTags = false
                                    } catch {
                                        self.error = error
                                    }
                                }
                            }
                        }
                }
                .onChange(of: selection ?? "", { _, newValue in
                    
                })
                .errorAlert($error)
                .scrollContentBackground(.hidden)
            }
        }
    }
}

#Preview {
    @Previewable @State var showingTags = false
    TagsContentView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), showingTags: $showingTags, tags: ["v1.0.0", "v1.1.0", "v2.0.0"], onTapDeleteButton: { _ in })
        .frame(width: 300, height: 660)
}

#Preview("No Content") {
    @Previewable @State var showingTags = false
    TagsContentView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), showingTags: $showingTags, tags: [], onTapDeleteButton: { _ in })
        .frame(width: 300, height: 660)
}
